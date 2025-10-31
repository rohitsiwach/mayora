# Migration Checklist

## ✅ Pre-Migration (COMPLETED)
- [x] Created hierarchical Firestore service
- [x] Updated all service layer code
- [x] Updated all UI components
- [x] Created migration script
- [x] Created new Firestore rules
- [x] All code compiles successfully
- [x] Created migration helper script

## 📋 Migration Execution Steps

### 1. Download Firebase Service Account Key
- [ ] Go to [Firebase Console](https://console.firebase.google.com)
- [ ] Select your project
- [ ] Navigate to: Project Settings → Service Accounts
- [ ] Click "Generate New Private Key"
- [ ] Save file as: `scripts/serviceAccountKey.json`

### 2. Run Dry Run Migration
```powershell
.\migrate.ps1
# Select option 1
```
- [ ] Dry run completed successfully
- [ ] Review number of documents to be migrated
- [ ] Verify organization ID is correct: `pWiofGzlPXMfoBNoMbP6`

### 3. Run Actual Migration
```powershell
.\migrate.ps1
# Select option 2
```
- [ ] Migration completed successfully
- [ ] Check Firebase Console to verify data structure

### 4. Deploy New Firestore Rules
```powershell
.\migrate.ps1
# Select option 3
```
- [ ] Rules deployed successfully
- [ ] Verify rules in Firebase Console

### 5. Test the Application
```powershell
.\migrate.ps1
# Select option 4
```

Test all features:
- [ ] User login works
- [ ] Users page loads correctly
- [ ] Projects page loads correctly
- [ ] Schedule page works
- [ ] Can create new schedule
- [ ] Can view schedules
- [ ] Can submit leave request
- [ ] Can view leave requests
- [ ] Can approve/reject leaves (if admin)
- [ ] Calendar widget shows schedules
- [ ] Calendar widget shows leaves
- [ ] Can view colleague schedules
- [ ] Today's colleagues view works

### 6. Verify Data in Firebase Console
- [ ] `organizations/{orgId}/users/{userId}` has full user data
- [ ] `organizations/{orgId}/users/{userId}/schedules` has schedules
- [ ] `organizations/{orgId}/users/{userId}/leaves` has leaves
- [ ] `organizations/{orgId}/projects` has projects
- [ ] `organizations/{orgId}/user_groups` has user groups
- [ ] Top-level `users/{userId}` only has lookup data (organizationId, email, userId)

### 7. Monitor for 1 Week
- [ ] Day 1: Basic functionality check
- [ ] Day 3: Check for any errors in logs
- [ ] Day 7: Full regression testing

### 8. Cleanup Old Data (AFTER 1 WEEK)
⚠️ **ONLY after thorough testing and verification!**

- [ ] Backup Firestore before cleanup
- [ ] Create cleanup script
- [ ] Run cleanup in dry-run mode
- [ ] Execute actual cleanup
- [ ] Verify app still works

---

## 🆘 Troubleshooting

### Migration Script Errors

**Error: "Could not load default credentials"**
- Solution: Make sure `serviceAccountKey.json` exists in `scripts/` folder
- Solution: Check file path in environment variable

**Error: "Organization does not exist"**
- Solution: Verify organization ID: `pWiofGzlPXMfoBNoMbP6`
- Solution: Check Firebase Console for correct org ID

**Error: "Permission denied"**
- Solution: Ensure service account has "Firebase Admin SDK Administrator Service Agent" role
- Solution: Regenerate service account key

### App Errors After Migration

**"Permission denied" when viewing data**
- Check that new Firestore rules are deployed
- Verify rules in Firebase Console
- Check organizationId is set correctly for users

**Data not showing up**
- Check Firebase Console to verify migration completed
- Check browser console for errors
- Verify organizationId lookup is working

**Old data still appearing**
- App might be caching old queries
- Clear browser cache
- Do hard refresh (Ctrl+Shift+R)

---

## 📞 Support

If you encounter issues:
1. Check the browser console for errors (F12)
2. Check Firebase Console for data structure
3. Review migration script output
4. Check Firestore rules are deployed

---

## 🎯 Success Criteria

Migration is successful when:
✅ All app features work correctly
✅ Users can only see their organization's data
✅ New data is created in hierarchical structure
✅ No permission errors in console
✅ Performance is acceptable
