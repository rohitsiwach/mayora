# Firestore Data Migration Execution Guide

## Step 1: Get Your Organization ID

You need to find your organization ID from Firebase Console:

1. Open Firebase Console: https://console.firebase.google.com
2. Select your project
3. Go to Firestore Database
4. Open the `organizations` collection
5. Copy the document ID (should be something like `pWiofGzlPXMfoBNoMbP6`)

**From previous screenshots, your organization ID is:** `pWiofGzlPXMfoBNoMbP6`

---

## Step 2: Set Up Firebase Admin Credentials

### Option A: Using Service Account Key (Recommended for local development)

1. **Download Service Account Key:**
   - Go to Firebase Console > Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Save the JSON file as `serviceAccountKey.json` in the `scripts` folder
   - **IMPORTANT:** Add `scripts/serviceAccountKey.json` to `.gitignore`

2. **Set Environment Variable:**
   ```powershell
   # In PowerShell
   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\Siwach\Desktop\Mayora\mayora\scripts\serviceAccountKey.json"
   ```

### Option B: Using Application Default Credentials

1. Install Google Cloud SDK
2. Run: `gcloud auth application-default login`

---

## Step 3: Install Dependencies

```powershell
cd scripts
npm install
```

---

## Step 4: Run Dry Run Migration (RECOMMENDED FIRST)

This will show you what would be migrated WITHOUT actually changing data:

```powershell
# From the scripts directory
npm run migrate-org -- --org-id=pWiofGzlPXMfoBNoMbP6 --dry-run
```

**Expected Output:**
```
🚀 Starting migration to hierarchical organization structure
Organization ID: pWiofGzlPXMfoBNoMbP6
Dry run: YES

✓ Organization found: Your Company Name

=== Migrating users to organizations/pWiofGzlPXMfoBNoMbP6/users ===
Found X users.
[DRY RUN] Would migrate X users with their subcollections.

=== Migrating projects to organizations/pWiofGzlPXMfoBNoMbP6/projects ===
Found X documents in projects.
[DRY RUN] Would migrate X docs.

... (similar for other collections)

✓ DRY RUN COMPLETE - Would migrate XX total documents
Run without --dry-run to perform actual migration.
```

---

## Step 5: Review What Will Be Migrated

The dry run will show you:
- How many users will be migrated
- How many schedules and leaves under each user
- How many projects, user_groups, locations, etc.

**Verify this matches your expectations before proceeding!**

---

## Step 6: Run Actual Migration

Once you're satisfied with the dry run results:

```powershell
npm run migrate-org -- --org-id=pWiofGzlPXMfoBNoMbP6
```

**This will:**
1. Copy users from `users/{userId}` → `organizations/{orgId}/users/{userId}`
2. Copy user subcollections:
   - `users/{userId}/schedules` → `organizations/{orgId}/users/{userId}/schedules`
   - `users/{userId}/leaves` → `organizations/{orgId}/users/{userId}/leaves`
3. Update top-level `users/{userId}` to lightweight lookup (organizationId, email, userId)
4. Migrate projects, user_groups, locations, etc. to org hierarchy

---

## Step 7: Deploy New Firestore Rules

```powershell
# From project root
cd ..
cp firestore.rules.new firestore.rules
firebase deploy --only firestore:rules
```

---

## Step 8: Test the Application

1. Run the Flutter app: `flutter run -d chrome`
2. Test all features:
   - User login
   - View users page
   - View projects
   - View schedules
   - Create/view leave requests
   - Calendar views

---

## Step 9: Verify Data in Firebase Console

Check Firebase Console to confirm:
- `organizations/{orgId}/users/{userId}` contains full user data
- `organizations/{orgId}/users/{userId}/schedules` has schedules
- `organizations/{orgId}/users/{userId}/leaves` has leaves
- `organizations/{orgId}/projects` has projects
- Top-level `users/{userId}` only has { organizationId, email, userId }

---

## Step 10: Cleanup (After 1 Week of Testing)

Only after you've verified everything works for at least 1 week:

```javascript
// Manual cleanup script (DO NOT RUN YET!)
// This permanently deletes old data structure

const cleanupOldData = async () => {
  // Delete old user subcollections (schedules, leaves were copied)
  // Keep top-level users collection (now used for lookups)
  
  // Delete old flat collections:
  // - projects (if organizationId matches)
  // - user_groups
  // - location_settings
  // - work_locations
};
```

---

## Troubleshooting

### Error: "Organization does not exist"
- Verify organization ID is correct
- Check that the organization document exists in Firestore

### Error: "Could not load default credentials"
- Make sure you've set `GOOGLE_APPLICATION_CREDENTIALS` environment variable
- Or run `gcloud auth application-default login`

### Error: "Permission denied"
- Ensure service account has Firestore Admin role
- Check that Firebase project is selected correctly

### Migration seems stuck
- Large datasets may take time
- The script processes in batches of 400 documents
- Check Firebase Console to see data appearing

---

## Important Notes

1. **Non-Destructive:** The migration COPIES data, it doesn't delete the original
2. **Reversible:** Original data remains intact until you manually clean it up
3. **Test First:** Always run with --dry-run first
4. **Backup:** Consider backing up Firestore before migration (Firebase Console > Firestore > Import/Export)
5. **Downtime:** No downtime needed - old and new structures coexist until you're ready

---

## Quick Command Reference

```powershell
# Set credentials (PowerShell)
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\Siwach\Desktop\Mayora\mayora\scripts\serviceAccountKey.json"

# Install dependencies
cd scripts
npm install

# Dry run
npm run migrate-org -- --org-id=pWiofGzlPXMfoBNoMbP6 --dry-run

# Actual migration
npm run migrate-org -- --org-id=pWiofGzlPXMfoBNoMbP6

# Deploy rules
cd ..
cp firestore.rules.new firestore.rules
firebase deploy --only firestore:rules

# Run app
flutter run -d chrome
```
