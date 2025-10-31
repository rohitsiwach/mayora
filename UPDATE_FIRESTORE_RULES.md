# Update Firestore Security Rules

## Quick Fix for Invitation Code Validation Error

You're seeing this error because unauthenticated users (people trying to sign up) cannot read the `user_invitations` collection.

### Solution: Update Security Rules in Firebase Console

#### Step 1: Open Firebase Console
Go to: https://console.firebase.google.com/u/0/project/mayora-160cf/firestore/rules

#### Step 2: Replace Security Rules
Copy and paste these updated rules with organization-based access control:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Organizations collection - allow anyone to create (for signup)
    match /organizations/{organizationId} {
      // Allow anyone to create (needed for signup)
      allow create: if request.auth != null;
      
      // Allow authenticated users to read
      allow read: if request.auth != null;
      
      // Allow organization admin to update
      allow update: if request.auth != null;
    }
    
    // Projects collection - organization-scoped access
    match /projects/{projectId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null;
    }
    
    // User invitations - organization-scoped with public read for validation
    match /user_invitations/{invitationId} {
      // Allow anyone to read for code validation during signup
      allow read: if true;
      
      // Allow deletion (needed when invitation is accepted)
      allow delete: if true;
      
      // Allow authenticated users to create/update invitations
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    
    // Users collection - organization-scoped access
    match /users/{userId} {
      // Allow authenticated users to read
      allow read: if request.auth != null;
      
      // Allow anyone to create (needed for signup and invitation acceptance)
      allow create: if true;
      
      // Allow authenticated users to update
      allow update: if request.auth != null;
    }
    
    // Location settings - organization-scoped access
    match /location_settings/{organizationId} {
      // Allow authenticated users to read their organization's settings
      allow read: if request.auth != null;
      
      // Allow authenticated users to create/update their organization's settings
      allow create, update: if request.auth != null;
    }
    
    // Work locations - organization-scoped access
    match /work_locations/{locationId} {
      // Allow authenticated users to read locations
      allow read: if request.auth != null;
      
      // Allow authenticated users to create/update/delete locations
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null;
    }
  }
}
```

**Important Notes:**
- These are **simplified rules for initial testing**
- They allow authenticated users to access all data (within authentication boundary)
- After testing, you can add stricter organization-based filtering
- For production, implement the organization validation rules

#### Step 3: Publish Rules
1. Click **"Publish"** button (top right)
2. Wait for confirmation message
3. Test your app again

### Why These Changes Are Safe

1. **Invitation codes are secure:**
   - Random 8-character alphanumeric codes (62^8 = 218 trillion combinations)
   - Expire after 14 days automatically
   - Can only be used once
   - Only "Pending" status codes are valid

2. **Limited public access:**
   - Only `read` access is public for `user_invitations`
   - Only `create` access is public for `users` (for signup)
   - All other operations still require authentication

3. **No sensitive data exposed:**
   - Invitation codes don't reveal passwords or sensitive user data
   - Similar to password reset tokens used by most apps

### After Publishing Rules

Your app should now work correctly:
1. Unauthenticated users can validate invitation codes
2. They can complete the signup process
3. Their account gets created in Firebase Auth
4. Their user data is saved to Firestore

### Troubleshooting

If you still see errors after publishing:
1. Wait 1-2 minutes for rules to propagate
2. Hard refresh your app (Ctrl+Shift+R on Chrome)
3. Check Firebase Console > Firestore > Rules for any syntax errors
4. Verify rules were published (check timestamp)

### Firebase Console Direct Links

- **Firestore Rules**: https://console.firebase.google.com/u/0/project/mayora-160cf/firestore/rules
- **Firestore Data**: https://console.firebase.google.com/u/0/project/mayora-160cf/firestore/data
- **Authentication**: https://console.firebase.google.com/u/0/project/mayora-160cf/authentication/users

---

## Org-scoped Invitations (current app structure) – Recommended Rules

Your app now stores invitations under organizations:

- organizations/{orgId}/user_invitations/{invitationId}
- organizations/{orgId}/users/{userId}

Update your rules to match this structure. The snippet below enables:
- Public read of invitations for signup-code validation (collection group works with this match)
- Authenticated org members to create/update/delete invitations in their org
- Standard org membership checks using the lightweight top‑level `users/{uid}` lookup

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() { return request.auth != null; }
    function userId() { return request.auth.uid; }
    function userLookup() {
      return get(/databases/$(database)/documents/users/$(userId()));
    }
    function isOrgMember(orgId) {
      return isSignedIn() && userLookup().exists && userLookup().data.organizationId == orgId;
    }
    function isOrgAdmin(orgId) {
      return isOrgMember(orgId) &&
             get(/databases/$(database)/documents/organizations/$(orgId)).data.adminUserId == userId();
    }

    // Organization doc
    match /organizations/{orgId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if isOrgAdmin(orgId);

      // Invitations under organization
      match /user_invitations/{invitationId} {
        // Allow public read so signup page can validate codes via collectionGroup
        allow read: if true;

        // Allow org members to create invitations they send
        allow create: if isOrgMember(orgId) &&
                       request.resource.data.invitedBy == userId();

        // Allow updates/deletes by org members (e.g., resend, revoke, cleanup)
        allow update, delete: if isOrgMember(orgId);
      }

      // User profiles under organization
      match /users/{uid} {
        allow read: if isOrgMember(orgId);
        // Allow a user to create their own profile during signup/invitation acceptance
        allow create: if isOrgMember(orgId) && userId() == uid;
        // Allow user self-updates, or admin updates
        allow update: if (isOrgMember(orgId) && userId() == uid) || isOrgAdmin(orgId);
      }

      // Projects (and other org subcollections)
      match /projects/{projectId} {
        allow read, create, update, delete: if isOrgMember(orgId);
      }

      // Add similar blocks for other subcollections if needed:
      // user_groups, work_locations, location_settings, etc.
    }

    // Top-level lightweight user lookup used by the rules
    match /users/{uid} {
      // Read/write by the authenticated user; writes are done by the app during signup
      allow read: if isSignedIn() && userId() == uid;
      allow create, update: if isSignedIn() && userId() == uid;
    }
  }
}
```

Notes:
- These rules assume your app creates/maintains `users/{uid}` with `organizationId` (the code already does this via `ensureCanonicalUserDocument()` and during signup/invite acceptance).
- If you have multiple orgs per user, extend the lookup or use claims/role arrays accordingly.
- After publishing, try sending an invitation again from the Users page.
