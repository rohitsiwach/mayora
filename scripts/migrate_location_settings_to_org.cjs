#!/usr/bin/env node
/**
 * Copy top-level location_settings/{orgId} to organizations/{orgId}/location_settings/{orgId}
 * Use when original settings doc didn't include organizationId and was skipped by bulk migration.
 * Usage: node migrate_location_settings_to_org.cjs --org-id=<ORG_ID>
 */
const admin = require('firebase-admin');

async function main() {
  const args = process.argv.slice(2);
  let orgId = null;
  for (const arg of args) if (arg.startsWith('--org-id=')) orgId = arg.split('=')[1];
  if (!orgId) {
    console.error('Usage: node migrate_location_settings_to_org.cjs --org-id=<ORG_ID>');
    process.exit(1);
  }

  admin.initializeApp({ credential: admin.credential.applicationDefault() });
  const db = admin.firestore();

  const sourceRef = db.collection('location_settings').doc(orgId);
  const sourceSnap = await sourceRef.get();
  if (!sourceSnap.exists) {
    console.log(`No top-level location_settings/${orgId} to migrate.`);
    return;
  }

  const targetRef = db.collection('organizations').doc(orgId).collection('location_settings').doc(orgId);
  const data = sourceSnap.data() || {};

  await targetRef.set({
    ...data,
    organizationId: orgId,
    migratedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`Copied location_settings/${orgId} -> organizations/${orgId}/location_settings/${orgId}`);
}

main().catch((e) => { console.error(e); process.exit(1); });
