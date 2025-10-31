#!/usr/bin/env node
/**
 * Migrate Firestore data to hierarchical organization structure.
 * 
 * NEW STRUCTURE:
 * organizations/{orgId}/
 *   ├── users/{userId}/
 *   │   ├── schedules/{scheduleId}
 *   │   └── leaves/{leaveId}
 *   ├── projects/{projectId}
 *   ├── location_settings/{settingId}
 *   ├── work_locations/{locationId}
 *   └── user_groups/{groupId}
 * 
 * Top-level users/{authUid} kept for org lookup: { organizationId, email }
 * 
 * Usage:
 *   node migrate_to_org_hierarchy.cjs [--dry-run] [--org-id=ORG_ID]
 */
const admin = require('firebase-admin');

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

async function migrateCollection(db, collectionName, orgId, dryRun) {
  console.log(`\n=== Migrating ${collectionName} to organizations/${orgId}/${collectionName} ===`);
  
  const sourceCol = db.collection(collectionName);
  const query = orgId 
    ? sourceCol.where('organizationId', '==', orgId)
    : sourceCol;
  
  const snapshot = await query.get();
  
  if (snapshot.empty) {
    console.log(`No documents found in ${collectionName}.`);
    return 0;
  }
  
  console.log(`Found ${snapshot.size} documents in ${collectionName}.`);
  
  if (dryRun) {
    console.log(`[DRY RUN] Would migrate ${snapshot.size} docs.`);
    return snapshot.size;
  }
  
  const targetCol = db.collection('organizations').doc(orgId).collection(collectionName);
  
  for (const batchDocs of chunk(snapshot.docs, 400)) {
    const batch = db.batch();
    for (const doc of batchDocs) {
      const targetRef = targetCol.doc(doc.id);
      batch.set(targetRef, doc.data(), { merge: true });
    }
    await batch.commit();
  }
  
  console.log(`✓ Migrated ${snapshot.size} documents to organizations/${orgId}/${collectionName}`);
  return snapshot.size;
}

async function migrateUsers(db, orgId, dryRun) {
  console.log(`\n=== Migrating users to organizations/${orgId}/users ===`);
  
  const sourceCol = db.collection('users');
  const query = orgId
    ? sourceCol.where('organizationId', '==', orgId)
    : sourceCol;
  
  const snapshot = await query.get();
  
  if (snapshot.empty) {
    console.log('No users found.');
    return 0;
  }
  
  console.log(`Found ${snapshot.size} users.`);
  
  if (dryRun) {
    console.log(`[DRY RUN] Would migrate ${snapshot.size} users with their subcollections.`);
    return snapshot.size;
  }
  
  let migrated = 0;
  
  for (const userDoc of snapshot.docs) {
    const userId = userDoc.id;
    const userData = userDoc.data();
    
    // 1) Create full user doc under org
    const targetUserRef = db.collection('organizations').doc(orgId).collection('users').doc(userId);
    await targetUserRef.set(userData, { merge: true });
    
    // 2) Migrate subcollections (schedules, leaves)
    const subcols = await db.collection('users').doc(userId).listCollections();
    for (const subcol of subcols) {
      const subDocs = await subcol.get();
      if (!subDocs.empty) {
        for (const batchDocs of chunk(subDocs.docs, 400)) {
          const batch = db.batch();
          for (const subDoc of batchDocs) {
            const targetSubRef = targetUserRef.collection(subcol.id).doc(subDoc.id);
            batch.set(targetSubRef, subDoc.data(), { merge: true });
          }
          await batch.commit();
        }
        console.log(`  - Migrated ${subDocs.size} docs from users/${userId}/${subcol.id}`);
      }
    }
    
    // 3) Update top-level user doc to lightweight lookup (organizationId + email only)
    const lookupData = {
      organizationId: userData.organizationId,
      email: userData.email || '',
      userId: userId
    };
    await db.collection('users').doc(userId).set(lookupData, { merge: false });
    
    migrated++;
  }
  
  console.log(`✓ Migrated ${migrated} users with subcollections to organizations/${orgId}/users`);
  console.log(`✓ Updated ${migrated} top-level user docs to lightweight lookup format`);
  return migrated;
}

async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  
  let orgId = null;
  for (const arg of args) {
    if (arg.startsWith('--org-id=')) {
      orgId = arg.split('=')[1];
    }
  }
  
  if (!orgId) {
    console.error('Usage: node migrate_to_org_hierarchy.cjs --org-id=ORG_ID [--dry-run]');
    console.error('Example: node migrate_to_org_hierarchy.cjs --org-id=pWiofGzlPXMfoBNoMbP6 --dry-run');
    process.exit(1);
  }
  
  admin.initializeApp({ credential: admin.credential.applicationDefault() });
  const db = admin.firestore();
  
  console.log(`\n🚀 Starting migration to hierarchical organization structure`);
  console.log(`Organization ID: ${orgId}`);
  console.log(`Dry run: ${dryRun ? 'YES' : 'NO'}\n`);
  
  // Verify org exists
  const orgSnap = await db.collection('organizations').doc(orgId).get();
  if (!orgSnap.exists) {
    console.error(`❌ Organization ${orgId} does not exist!`);
    process.exit(1);
  }
  
  console.log(`✓ Organization found: ${orgSnap.data().name || 'Unknown'}`);
  
  let totalMigrated = 0;
  
  // Migrate each collection type
  totalMigrated += await migrateUsers(db, orgId, dryRun);
  totalMigrated += await migrateCollection(db, 'projects', orgId, dryRun);
  totalMigrated += await migrateCollection(db, 'location_settings', orgId, dryRun);
  totalMigrated += await migrateCollection(db, 'work_locations', orgId, dryRun);
  totalMigrated += await migrateCollection(db, 'user_groups', orgId, dryRun);
  
  console.log(`\n${'='.repeat(60)}`);
  if (dryRun) {
    console.log(`✓ DRY RUN COMPLETE - Would migrate ${totalMigrated} total documents`);
    console.log(`Run without --dry-run to perform actual migration.`);
  } else {
    console.log(`✅ MIGRATION COMPLETE - Migrated ${totalMigrated} total documents`);
    console.log(`\nNext steps:`);
    console.log(`1. Verify data in Firebase Console`);
    console.log(`2. Deploy new Firestore rules`);
    console.log(`3. Update and deploy Flutter app`);
    console.log(`4. Test thoroughly`);
    console.log(`5. Delete old top-level collections after verification`);
  }
  console.log(`${'='.repeat(60)}\n`);
}

main().catch((err) => {
  console.error('❌ Migration failed:', err);
  process.exit(1);
});
