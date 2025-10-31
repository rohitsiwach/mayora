#!/usr/bin/env node
/**
 * Scan for duplicate users within an organization, grouped by email.
 * Usage:
 *   node scan_duplicate_org_users.cjs --org-id=<ORG_ID>
 */
const admin = require('firebase-admin');

async function main() {
  const args = process.argv.slice(2);
  let orgId = null;
  for (const arg of args) if (arg.startsWith('--org-id=')) orgId = arg.split('=')[1];
  if (!orgId) {
    console.error('Usage: node scan_duplicate_org_users.cjs --org-id=<ORG_ID>');
    process.exit(1);
  }

  admin.initializeApp({ credential: admin.credential.applicationDefault() });
  const db = admin.firestore();

  const usersSnap = await db.collection('organizations').doc(orgId).collection('users').get();
  if (usersSnap.empty) {
    console.log(`No users found in organizations/${orgId}/users`);
    return;
  }

  const byEmail = new Map();
  for (const doc of usersSnap.docs) {
    const data = doc.data() || {};
    const email = (data.email || '').toLowerCase();
    const arr = byEmail.get(email) || [];
    arr.push({ id: doc.id, email, name: data.name || data.displayName || '' });
    byEmail.set(email, arr);
  }

  let dupCount = 0;
  for (const [email, arr] of byEmail.entries()) {
    if (email && arr.length > 1) {
      dupCount++;
      console.log(`\nDuplicate email '${email}':`);
      for (const u of arr) console.log(` - ${u.id} (${u.name})`);
    }
  }

  if (dupCount === 0) console.log('No duplicates by email found.');
  else console.log(`\nFound ${dupCount} duplicate email group(s).`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
