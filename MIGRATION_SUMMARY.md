# Hierarchical Architecture Migration - Implementation Summary

## What We've Built

### 1. Migration Script ✅
**File:** `scripts/migrate_to_org_hierarchy.cjs`

**What it does:**
- Moves all users from `users/` → `organizations/{orgId}/users/`
- Copies all subcollections (schedules, leaves) for each user
- Moves projects, user_groups, location_settings, work_locations under org
- Converts top-level user docs to lightweight lookup format: `{ organizationId, email, userId }`

**Usage:**
```powershell
cd scripts
# Dry run first (no writes)
npm run migrate-org -- --org-id=YOUR_ORG_ID --dry-run

# Actual migration
npm run migrate-org -- --org-id=YOUR_ORG_ID
```

**Your organization ID:** `pWiofGzlPXMfoBNoMbP6` (from screenshots)

---

### 2. New Firestore Rules ✅
**File:** `firestore.rules.new`

**Key improvements:**
- Path-based security instead of field-based checks
- Simple helper functions: `isOrgMember(orgId)`, `isOrgAdminOrManager(orgId)`
- Automatic isolation - can't accidentally query another org's data
- Much simpler to read and maintain

**Example old rule:**
```javascript
allow read: if request.auth != null && 
  get(/databases/$(database)/documents/users/$(request.auth.uid)).data.organizationId == resource.data.organizationId
```

**Example new rule:**
```javascript
allow read: if isOrgMember(orgId);
```

**Deploy command:**
```powershell
cp firestore.rules.new firestore.rules
firebase deploy --only firestore:rules
```

---

### 3. Hierarchical Firestore Service ✅
**File:** `lib/services/hierarchical_firestore_service.dart`

**What it provides:**
- Path helper methods that handle hierarchical structure
- CRUD operations for all collections
- Lightweight org lookup from top-level users/{uid}
- Caching of organizationId for performance

**Key methods:**
```dart
// Path builders
usersCollection(orgId) → organizations/{orgId}/users
userDoc(orgId, userId) → organizations/{orgId}/users/{userId}
schedulesCollection(orgId, userId) → organizations/{orgId}/users/{userId}/schedules
projectsCollection(orgId) → organizations/{orgId}/projects

// Operations
getCurrentUserOrganizationId() → reads from lightweight users/{uid}
createUserProfile(orgId, userId, data)
streamOrgUsers(orgId)
createProject(orgId, projectData)
createSchedule(orgId, userId, scheduleData)
```

---

## Next Steps (App Code Updates)

### Step 1: Update Service Layer

**Required changes** (search & replace pattern):

**Pattern 1: Replace flat collection queries**
```dart
// OLD
_firestore.collection('users').where('organizationId', isEqualTo: orgId)

// NEW
_hierarchicalService.usersCollection(orgId)
```

**Pattern 2: Replace user subcollection queries**
```dart
// OLD
_firestore.collection('users').doc(userId).collection('schedules')

// NEW
_hierarchicalService.schedulesCollection(orgId, userId)
```

**Pattern 3: Replace project queries**
```dart
// OLD
_firestore.collection('projects').where('organizationId', isEqualTo: orgId)

// NEW
_hierarchicalService.projectsCollection(orgId)
```

**Files that need updates:**
1. ✅ `lib/services/hierarchical_firestore_service.dart` (DONE - new service)
2. ⏳ `lib/services/firestore_service.dart` (50+ collection references)
3. ⏳ `lib/services/organization_service.dart` (createDefaultProject)
4. ⏳ `lib/services/leave_service.dart` (all user/leaves queries)
5. ⏳ `lib/services/schedule_service.dart` (schedule queries)
6. ⏳ `lib/pages/sign_up_page.dart` (create user in org)
7. ⏳ `lib/pages/users_page.dart`
8. ⏳ `lib/pages/projects_page.dart`
9. ⏳ `lib/pages/schedule_page.dart`
10. ⏳ `lib/widgets/shift_calendar_widget.dart`
11. ⏳ `lib/widgets/today_colleagues_schedule_view.dart`

---

## Migration Execution Plan

### Phase 1: Prepare (30 minutes)
1. Review `MIGRATION_GUIDE.md`
2. Set up Firebase credentials for migration script
3. Find your organization ID

### Phase 2: Migrate Data (15 minutes)
1. Run dry-run migration
2. Review output
3. Run actual migration
4. Verify in Firebase Console

### Phase 3: Deploy Rules (5 minutes)
1. Backup current rules
2. Deploy new hierarchical rules
3. Test basic auth (should still work)

### Phase 4: Update App Code (2-4 hours)
1. Update all service layer files to use `HierarchicalFirestoreService`
2. Update all UI components
3. Update signup flow
4. Test each feature as you update it

### Phase 5: Deploy & Test (1 hour)
1. Deploy Flutter web app
2. Test all features thoroughly
3. Monitor for errors

### Phase 6: Cleanup (optional, after 1 week)
1. Delete old top-level collections if everything works
2. Remove backup files

---

## Quick Start Commands

### Get your organization ID
```powershell
# From Firebase Console: Firestore > organizations collection
# Or from your app's debug output
```

### Run migration (DRY RUN first!)
```powershell
cd C:\Users\Siwach\Desktop\Mayora\mayora\scripts
npm run migrate-org -- --org-id=pWiofGzlPXMfoBNoMbP6 --dry-run
```

### Deploy new rules
```powershell
cd C:\Users\Siwach\Desktop\Mayora\mayora
cp firestore.rules firestore.rules.backup
cp firestore.rules.new firestore.rules
firebase deploy --only firestore:rules
```

### Format Dart code after updates
```powershell
dart format lib/
```

---

## Rollback Plan

If something breaks:

1. **Restore old rules:**
   ```powershell
   cp firestore.rules.backup firestore.rules
   firebase deploy --only firestore:rules
   ```

2. **Revert app code:**
   ```powershell
   git checkout HEAD -- lib/
   ```

3. **Old data is preserved** - migration copies, doesn't delete

---

## Questions?

- Migration script: `scripts/migrate_to_org_hierarchy.cjs`
- New rules: `firestore.rules.new`
- Helper service: `lib/services/hierarchical_firestore_service.dart`
- Full guide: `MIGRATION_GUIDE.md`
- This summary: `MIGRATION_SUMMARY.md`

**Ready to proceed?** Start with Phase 2 (migrate data) since it's non-destructive and you can verify before deploying rules or updating app code.
