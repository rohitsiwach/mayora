#!/usr/bin/env node
/**
 * Merge a source user document into a target user document in Firestore.
 * Usage:
 *   node merge_user_docs.cjs <SOURCE_USER_ID> <TARGET_USER_ID> [--dry-run] [--no-delete]
 */
const admin = require('firebase-admin');

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

async function main() {
  const args = process.argv.slice(2);
  const sourceUserId = args[0];
  const targetUserId = args[1];
  const dryRun = args.includes('--dry-run');
  const noDelete = args.includes('--no-delete');

  if (!sourceUserId || !targetUserId) {
    console.error('Usage: node merge_user_docs.cjs <SOURCE_USER_ID> <TARGET_USER_ID> [--dry-run] [--no-delete]');
    process.exit(1);
  }

  admin.initializeApp({ credential: admin.credential.applicationDefault() });
  const db = admin.firestore();

  const sourceRef = db.collection('users').doc(sourceUserId);
  const targetRef = db.collection('users').doc(targetUserId);

  const [sourceSnap, targetSnap] = await Promise.all([sourceRef.get(), targetRef.get()]);
  if (!sourceSnap.exists) {
    console.error(`Source user '${sourceUserId}' does not exist.`);
    process.exit(1);
  }

  console.log(`Merging user '${sourceUserId}' -> '${targetUserId}'`);
  console.log(`Dry run: ${dryRun ? 'YES' : 'NO'} | Delete source after copy: ${noDelete ? 'NO' : 'YES'}`);

  // 1) Merge top-level fields
  const sourceData = sourceSnap.data() || {};
  if (sourceData.userId && sourceData.userId !== targetUserId) {
    sourceData.userId = targetUserId; // normalize
  }

  if (dryRun) {
    console.log('[DRY RUN] Would merge top-level fields:', Object.keys(sourceData));
  } else {
    await targetRef.set(sourceData, { merge: true });
    console.log('Merged top-level fields into target.');
  }

  // 2) Copy subcollections
  const subcols = await sourceRef.listCollections();
  for (const col of subcols) {
    console.log(`Processing subcollection '${col.id}'...`);
    const docsSnap = await col.get();
    if (docsSnap.empty) {
      console.log(`- No documents in '${col.id}'.`);
      continue;
    }

    const docs = docsSnap.docs;
    if (dryRun) {
      console.log(`[DRY RUN] Would copy ${docs.length} docs from '${col.id}'.`);
    } else {
      for (const batchDocs of chunk(docs, 400)) { // stay under 500 operations per batch
        const batch = db.batch();
        for (const doc of batchDocs) {
          const targetDocRef = targetRef.collection(col.id).doc(doc.id);
          batch.set(targetDocRef, doc.data(), { merge: true });
        }
        await batch.commit();
      }
      console.log(`- Copied ${docs.length} docs from '${col.id}'.`);
    }
  }

  // 3) Optionally delete source subcollections and source doc
  if (!dryRun && !noDelete) {
    console.log('Deleting source subcollections and document...');
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
    console.log(`Deleted source user doc '${sourceUserId}'.`);
  } else {
    console.log('Skipped deletion step.');
  }

  console.log('Done.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
