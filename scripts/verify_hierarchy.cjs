#!/usr/bin/env node
/**
 * Verify hierarchical Firestore data integrity for a given orgId.
 */
const admin = require('firebase-admin');

async function main() {
  const args = process.argv.slice(2);
  let orgId = null;
  for (const arg of args) if (arg.startsWith('--org-id=')) orgId = arg.split('=')[1];
  if (!orgId) {
    console.error('Usage: node verify_hierarchy.cjs --org-id=ORG_ID');
    process.exit(1);
  }

  admin.initializeApp({ credential: admin.credential.applicationDefault() });
  const db = admin.firestore();

  console.log(`\nVerifying hierarchical data for org: ${orgId}`);

  const orgRef = db.collection('organizations').doc(orgId);
  const orgSnap = await orgRef.get();
  if (!orgSnap.exists) {
    console.error(`❌ Organization ${orgId} not found.`);
    process.exit(2);
  }

  // Users under org
  const usersSnap = await orgRef.collection('users').get();
  console.log(`- Org users: ${usersSnap.size}`);

  // Check a few users
  let checked = 0;
  for (const userDoc of usersSnap.docs.slice(0, 10)) {
    const uid = userDoc.id;
    const data = userDoc.data() || {};
    const name = data.name || data.email || uid;

    const schedulesSnap = await orgRef.collection('users').doc(uid).collection('schedules').limit(1).get();
    const leavesSnap = await orgRef.collection('users').doc(uid).collection('leaves').limit(1).get();

    console.log(`  • ${name} (${uid}) | schedules: ${schedulesSnap.size > 0 ? '✓' : '0'} | leaves: ${leavesSnap.size > 0 ? '✓' : '0'}`);
    checked++;
  }

  // Projects
  const projectsSnap = await orgRef.collection('projects').get();
  console.log(`- Org projects: ${projectsSnap.size}`);

  // User groups
  const groupsSnap = await orgRef.collection('user_groups').get();
  console.log(`- Org user_groups: ${groupsSnap.size}`);

  // Work locations
  const workLocationsSnap = await orgRef.collection('work_locations').get();
  console.log(`- Org work_locations: ${workLocationsSnap.size}`);

  // Location settings
  const locationSettingsCol = orgRef.collection('location_settings');
  const locSettingsSnap = await locationSettingsCol.get();
  if (locSettingsSnap.empty) {
    console.log(`- Org location_settings: MISSING (0 docs)`);
  } else {
    const hasOrgIdDoc = locSettingsSnap.docs.some((d) => d.id === orgId);
    console.log(`- Org location_settings: ${locSettingsSnap.size} doc(s) | has '${orgId}' doc: ${hasOrgIdDoc ? 'YES' : 'NO'}`);
    // Print a small preview of the effective settings (prefer orgId doc if present)
    const settingsDoc = hasOrgIdDoc
      ? locSettingsSnap.docs.find((d) => d.id === orgId)
      : locSettingsSnap.docs[0];
    const data = settingsDoc.data() || {};
    const keys = Object.keys(data).sort();
    console.log(`  • Settings doc '${settingsDoc.id}' keys: ${keys.slice(0, 8).join(', ')}${keys.length > 8 ? ' …' : ''}`);
  }

  // Lightweight top-level users
  const topUsersSnap = await db.collection('users').where('organizationId', '==', orgId).limit(5).get();
  let okLookup = true;
  for (const doc of topUsersSnap.docs) {
    const d = doc.data() || {};
    if (!d.organizationId || !d.email || !d.userId) okLookup = false;
  }
  console.log(`- Top-level users lookup shape OK: ${okLookup ? 'YES' : 'NO'}`);

  console.log('\nIntegrity check complete.');
}

main().catch((e) => { console.error('Verification failed:', e); process.exit(1); });
