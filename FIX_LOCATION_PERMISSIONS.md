# Quick Fix: Location Management Permissions

## Problem
You're seeing these errors:
- `Error getting location settings: [cloud_firestore/permission-denied]`
- `Error updating location settings: [cloud_firestore/permission-denied]`

## Solution
Add location collections to your Firestore Security Rules.

### Step 1: Open Firebase Console
Go to: **https://console.firebase.google.com/u/0/project/mayora-160cf/firestore/rules**

### Step 2: Add These Rules
Add the following sections to your existing Firestore rules (before the closing `}}`):

```javascript
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
```

### Step 3: Complete Rules File
Your complete rules should look like this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Organizations collection
    match /organizations/{organizationId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
      allow update: if request.auth != null;
    }
    
    // Projects collection
    match /projects/{projectId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null;
    }
    
    // User invitations
    match /user_invitations/{invitationId} {
      allow read: if true;
      allow delete: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if true;
      allow update: if request.auth != null;
    }
    
    // Location settings - NEW
    match /location_settings/{organizationId} {
      allow read: if request.auth != null;
      allow create, update: if request.auth != null;
    }
    
    // Work locations - NEW
    match /work_locations/{locationId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null;
    }
  }
}
```

### Step 4: Publish Rules
1. Click the **"Publish"** button (top right corner)
2. Wait for the confirmation message
3. Refresh your app and try again

### Step 5: Test
After publishing:
1. Hard refresh your app (Ctrl+Shift+R on Chrome)
2. Navigate to Location Management page
3. The errors should be gone

## What These Rules Do

- **`location_settings/{organizationId}`**: Stores settings like "Location Tracking Enabled", "Require Location for Punch", etc. One document per organization.
- **`work_locations/{locationId}`**: Stores individual work locations with name, address, coordinates, and radius.

Both collections require authentication, so only signed-in users can access them.

## Troubleshooting

If you still see errors after updating:
1. Wait 1-2 minutes for rules to propagate
2. Clear browser cache
3. Sign out and sign back in
4. Check the Firebase Console Rules tab for any syntax errors
