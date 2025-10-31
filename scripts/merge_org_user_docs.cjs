#!/usr/bin/env node
/**
 * Merge a source user document into a target user document within an organization.
 *
 * Structure affected:
 *   organizations/{orgId}/users/{userId} (top-level fields)
 *   organizations/{orgId}/users/{userId}/schedules/*
 *   organizations/{orgId}/users/{userId}/leaves/*
 *   users/{userId} (lightweight lookup) — source lookup optionally deleted
 *
 * Usage:
 *   node merge_org_user_docs.cjs --org-id=<ORG_ID> --source=<SOURCE_USER_ID> --target=<TARGET_USER_ID> [--dry-run] [--no-delete]
 *
 * Notes:
 * - Merges top-level fields (source -> target) with { merge: true }
 * - Copies subcollections (schedules, leaves, and any others) doc-by-doc from source -> target
 * - By default deletes source subcollection docs and source user doc after copy (omit with --no-delete)
 */
const admin = require('firebase-admin');

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = { dryRun: false, noDelete: false };
  for (const arg of args) {
    if (arg === '--dry-run') opts.dryRun = true;
    else if (arg === '--no-delete') opts.noDelete = true;
    else if (arg.startsWith('--org-id=')) opts.orgId = arg.split('=')[1];
    else if (arg.startsWith('--source=')) opts.sourceUserId = arg.split('=')[1];
    else if (arg.startsWith('--target=')) opts.targetUserId = arg.split('=')[1];
  }
  return opts;
}

async function mergeOrgUsers(db, orgId, sourceUserId, targetUserId, dryRun, noDelete) {
  const orgRef = db.collection('organizations').doc(orgId);
  const sourceRef = orgRef.collection('users').doc(sourceUserId);
  const targetRef = orgRef.collection('users').doc(targetUserId);

  const [sourceSnap, targetSnap] = await Promise.all([sourceRef.get(), targetRef.get()]);
  if (!sourceSnap.exists) throw new Error(`Source user organizations/${orgId}/users/${sourceUserId} does not exist.`);
  if (!targetSnap.exists) console.warn(`Target user organizations/${orgId}/users/${targetUserId} does not exist yet; it will be created.`);

  const sourceData = sourceSnap.data() || {};
  // Normalize obvious IDs in payload if present
  if (sourceData.userId && sourceData.userId !== targetUserId) sourceData.userId = targetUserId;
  if (sourceData.organizationId && sourceData.organizationId !== orgId) sourceData.organizationId = orgId;

  console.log(`Merging org user '${sourceUserId}' -> '${targetUserId}' in org '${orgId}'`);
  console.log(`Dry run: ${dryRun ? 'YES' : 'NO'} | Delete source after copy: ${noDelete ? 'NO' : 'YES'}`);

  if (dryRun) {
    console.log('[DRY RUN] Would merge top-level fields:', Object.keys(sourceData));
  } else {
    await targetRef.set(sourceData, { merge: true });
    console.log('Merged top-level fields into target.');
  }

  // Copy all subcollections (not only schedules/leaves, but those included)
  const subcols = await sourceRef.listCollections();
  for (const col of subcols) {
    const docsSnap = await col.get();
    if (docsSnap.empty) {
      console.log(`- No documents in subcollection '${col.id}'.`);
      continue;
    }
    if (dryRun) {
      console.log(`[DRY RUN] Would copy ${docsSnap.size} docs from '${col.id}'.`);
    } else {
      for (const batchDocs of chunk(docsSnap.docs, 400)) {
        const batch = db.batch();
        for (const doc of batchDocs) {
          const targetDocRef = targetRef.collection(col.id).doc(doc.id);
          batch.set(targetDocRef, doc.data(), { merge: true });
        }
        await batch.commit();
      }
      console.log(`- Copied ${docsSnap.size} docs from '${col.id}'.`);
    }
  }

  // Update top-level lookup docs:
  const sourceLookupRef = db.collection('users').doc(sourceUserId);
  const targetLookupRef = db.collection('users').doc(targetUserId);
  const [sourceLookupSnap, targetLookupSnap] = await Promise.all([
    sourceLookupRef.get(),
    targetLookupRef.get(),
  ]);

  if (dryRun) {
    if (sourceLookupSnap.exists) console.log(`[DRY RUN] Would delete top-level lookup users/${sourceUserId}.`);
    console.log(`[DRY RUN] Would ensure users/${targetUserId} contains { organizationId: '${orgId}', userId: '${targetUserId}', email: <preserved> }`);
  } else {
    // Ensure target lookup exists, preserving email from either source/target
    const sourceLookup = sourceLookupSnap.exists ? sourceLookupSnap.data() : {};
    const targetLookup = targetLookupSnap.exists ? targetLookupSnap.data() : {};
    const email = targetLookup.email || sourceLookup.email || '';
    await targetLookupRef.set({ organizationId: orgId, userId: targetUserId, email }, { merge: false });
    if (sourceLookupSnap.exists) {
      await sourceLookupRef.delete();
      console.log(`- Deleted top-level lookup users/${sourceUserId}.`);
    }
  }

  // Optionally delete source org user doc and its subcollections
  if (!dryRun && !noDelete) {
    console.log('Deleting source org user subcollections and document...');
    for (const col of await sourceRef.listCollections()) {
      const docsSnap = await col.get();
      if (!docsSnap.empty) {
        for (const batchDocs of chunk(docsSnap.docs, 400)) {
          const batch = db.batch();
          for (const doc of batchDocs) batch.delete(col.doc(doc.id));
          await batch.commit();
        }
        console.log(`- Deleted ${docsSnap.size} docs from '${col.id}'.`);
      }
    }
    await sourceRef.delete();
    console.log(`Deleted source org user doc '${sourceUserId}'.`);
  } else {
    console.log('Skipped deletion step.');
  }
}

async function main() {
  const { orgId, sourceUserId, targetUserId, dryRun, noDelete } = parseArgs();
  if (!orgId || !sourceUserId || !targetUserId) {
    console.error('Usage: node merge_org_user_docs.cjs --org-id=<ORG_ID> --source=<SOURCE_USER_ID> --target=<TARGET_USER_ID> [--dry-run] [--no-delete]');
    process.exit(1);
  }

  admin.initializeApp({ credential: admin.credential.applicationDefault() });
  const db = admin.firestore();

  await mergeOrgUsers(db, orgId, sourceUserId, targetUserId, dryRun, noDelete);
  console.log('Done.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
