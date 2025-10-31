# Firestore Hierarchical Architecture Migration

## Overview
Migrating from flat collections to hierarchical organization-based structure for better data isolation and simpler security rules.

## New Structure

```
organizations/{orgId}/
  ├── users/{userId}/
  │   ├── schedules/{scheduleId}
  │   └── leaves/{leaveId}
  ├── projects/{projectId}
  ├── location_settings/{settingId}
  ├── work_locations/{locationId}
  └── user_groups/{groupId}

users/{authUid}  (lightweight lookup: { organizationId, email, userId })
user_invitations/{invId}  (stays top-level for pre-signup access)
```

## Migration Steps

### Phase 1: Preparation (DO NOT DEPLOY YET)

1. **Review new rules** in `firestore.rules.new`
   - Simpler path-based security
   - No more cross-document organizationId checks
   - Helper functions for org membership

2. **Get your organization ID**
   ```powershell
   # From Firebase Console or your app
   # Example: pWiofGzlPXMfoBNoMbP6
   ```

### Phase 2: Data Migration

1. **Dry run first** (no writes, shows what would be migrated)
   ```powershell
   cd scripts
   npm run migrate-org -- --org-id=YOUR_ORG_ID --dry-run
   ```

2. **Review dry run output**
   - Check counts match expectations
   - Verify no errors

3. **Run actual migration**
   ```powershell
   npm run migrate-org -- --org-id=YOUR_ORG_ID
   ```

4. **Verify in Firebase Console**
   - Check organizations/{orgId}/users has all users
   - Check subcollections (schedules, leaves) were copied
   - Check top-level users/{uid} now lightweight (only organizationId, email, userId)
   - Check projects, user_groups, etc. moved under org

### Phase 3: Deploy New Rules

1. **Backup current rules**
   ```powershell
   cp firestore.rules firestore.rules.backup
   ```

2. **Replace with new rules**
   ```powershell
   cp firestore.rules.new firestore.rules
   ```

3. **Deploy rules**
   ```powershell
   firebase deploy --only firestore:rules
   ```

### Phase 4: Update Flutter App

#### Service Layer Changes

**firestore_service.dart**: All queries now use hierarchical paths
- `_getOrgPath()` helper returns `organizations/{orgId}`
- `_getUserPath()` returns `organizations/{orgId}/users/{userId}`
- All collection queries updated

**Files to update** (in order):
1. `lib/services/firestore_service.dart` ✓ (update all 50+ collection queries)
2. `lib/services/organization_service.dart` (update createDefaultProject)
3. `lib/services/leave_service.dart` (update all user/leaves queries)
4. `lib/services/schedule_service.dart` (update schedule queries)
5. `lib/pages/sign_up_page.dart` (create user in org hierarchy)
6. `lib/pages/users_page.dart` (query from org path)
7. `lib/pages/projects_page.dart` (query from org path)
8. `lib/pages/schedule_page.dart` (query from org paths)
9. `lib/widgets/shift_calendar_widget.dart` (query schedules from org path)
10. `lib/widgets/today_colleagues_schedule_view.dart` (query from org path)

#### Key Changes Pattern

**OLD:**
```dart
FirebaseFirestore.instance
  .collection('users')
  .where('organizationId', isEqualTo: orgId)
  .get();
```

**NEW:**
```dart
FirebaseFirestore.instance
  .collection('organizations')
  .doc(orgId)
  .collection('users')
  .get();
```

**OLD (subcollections):**
```dart
FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('schedules')
  .get();
```

**NEW:**
```dart
FirebaseFirestore.instance
  .collection('organizations')
  .doc(orgId)
  .collection('users')
  .doc(userId)
  .collection('schedules')
  .get();
```

### Phase 5: Testing

1. **Test authentication flow**
   - Sign in should work
   - getCurrentUserOrganizationId should read from lightweight users/{uid}

2. **Test users page**
   - Should list all org users
   - Should be able to edit user profiles

3. **Test projects page**
   - Should list org projects
   - Should create/update/delete projects

4. **Test schedule/calendar**
   - Should show own schedules
   - Should show colleagues' schedules
   - Should create shifts

5. **Test leaves**
   - Should create leave requests
   - Should approve/reject leaves (if admin)

### Phase 6: Cleanup (After 1 week of testing)

1. **Optional: Remove old top-level collections**
   ```javascript
   // Run this script ONLY after confirming everything works
   // This permanently deletes old data
   ```

2. **Update indexes if needed**
   ```powershell
   firebase deploy --only firestore:indexes
   ```

## Rollback Plan

If something goes wrong:

1. **Restore old rules**
   ```powershell
   cp firestore.rules.backup firestore.rules
   firebase deploy --only firestore:rules
   ```

2. **Old data is still there** - the migration copies data, doesn't delete it
   - Users still in top-level `users` collection
   - Projects still in top-level `projects` collection
   - etc.

3. **Revert app code** using git
   ```powershell
   git checkout HEAD -- lib/
   ```

## Benefits

✅ **Simpler security rules** - path-based instead of field-based checks
✅ **Better performance** - hierarchical queries are faster
✅ **Automatic isolation** - impossible to accidentally query another org's data
✅ **Easier deletion** - delete org → cascade deletes all nested data
✅ **Cleaner data model** - org owns all its data

## Support

- Migration script: `scripts/migrate_to_org_hierarchy.cjs`
- New rules: `firestore.rules.new`
- This guide: `MIGRATION_GUIDE.md`
