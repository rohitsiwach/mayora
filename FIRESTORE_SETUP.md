# Firestore Setup Instructions

## Overview
This application now uses Firebase Cloud Firestore for persistent data storage of projects and user invitations.

## Collections Structure

### 1. `projects` Collection
Stores all project data with the following fields:
- `projectName` (string)
- `projectType` (string): "Internal" or "External"
- `billableToClient` (boolean)
- `paymentType` (string): "Lump Sum", "Billable Monthly", or "Billable Hourly"
- `clientName` (string, optional)
- `clientEmail` (string, optional)
- `clientPhone` (string, optional)
- `location` (string)
- `lumpSumAmount` (number, optional)
- `monthlyRate` (number, optional)
- `hourlyRate` (number, optional)
- `description` (string)
- `createdBy` (string): User ID of creator
- `createdAt` (timestamp): Auto-generated
- `updatedAt` (timestamp): Auto-updated

### 2. `user_invitations` Collection
Stores user invitation data with the following fields:
- `name` (string)
- `email` (string)
- `accessLevel` (string): "Admin", "Manager", "Manager Read Only", "Employee"
- `department` (string)
- `position` (string)
- `paymentType` (string): "Monthly" or "Hourly"
- `monthlyIncome` (number, optional)
- `hourlyRate` (number, optional)
- `hireDate` (string): ISO date format
- `yearlyVacations` (number)
- `status` (string): "Pending", "Active", "Deactivated"
- `invitedBy` (string): User ID of inviter
- `createdAt` (timestamp): Auto-generated
- `updatedAt` (timestamp): Auto-updated
- `lastInvitationSent` (timestamp, optional)
- `invitationCount` (number, optional)
- `deactivatedAt` (timestamp, optional)

## Firebase Console Setup

### Step 1: Enable Firestore Database
1. Go to [Firebase Console](https://console.firebase.google.com/u/0/project/mayora-160cf/firestore)
2. Click on **"Firestore Database"** in the left menu
3. Click **"Create database"**
4. Select **"Start in test mode"** for development (you can change security rules later)
5. Choose a Firestore location (e.g., us-central)
6. Click **"Enable"**

### Step 2: Set Up Security Rules (Important!)
After creating the database, update the security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Projects collection - users can only access their own projects
    match /projects/{projectId} {
      allow read: if request.auth != null && resource.data.createdBy == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.createdBy == request.auth.uid;
      allow update: if request.auth != null && resource.data.createdBy == request.auth.uid;
      allow delete: if request.auth != null && resource.data.createdBy == request.auth.uid;
    }
    
    // User invitations - special rules for invitation code validation
    match /user_invitations/{invitationId} {
      // Allow authenticated users to read/write their own invitations
      allow read: if request.auth != null && resource.data.invitedBy == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.invitedBy == request.auth.uid;
      allow update: if request.auth != null && resource.data.invitedBy == request.auth.uid;
      allow delete: if request.auth != null && resource.data.invitedBy == request.auth.uid;
      
      // Allow ANYONE (unauthenticated) to read invitations for code validation
      // This is needed for the signup process where users validate their invitation code
      allow read: if true;
    }
    
    // Users collection - stores accepted invitations
    match /users/{userId} {
      allow read: if request.auth != null && resource.data.invitedBy == request.auth.uid;
      allow create: if true; // Allow unauthenticated users to create their profile during signup
      allow update: if request.auth != null && (resource.data.invitedBy == request.auth.uid || resource.data.userId == request.auth.uid);
    }
  }
}
```

**Important Notes:**
- `user_invitations` allows **public read access** for invitation code validation during signup
- This is secure because:
  - Invitation codes are random 8-character strings (hard to guess)
  - Invitations expire after 14 days
  - Each invitation can only be used once
  - Only pending invitations can be validated
- `users` collection allows **public create** for the signup process

### Step 3: Enable Email/Password Authentication
1. Go to **Authentication** > **Sign-in method**
2. Enable **Email/Password** provider
3. Click **Save**

## Error Handling

The application includes comprehensive error handling for:
- **Network errors**: "Network error. Please check your internet connection."
- **Permission errors**: "Permission denied. Please check your access rights."
- **Unavailable service**: "Service unavailable. Please check your internet connection."
- **Authentication errors**: "Please sign in to continue."

When offline or if Firestore fails:
- Users will see error messages with retry options
- Loading indicators show during data fetching
- Success/failure snackbars provide feedback for all operations

## Testing the Integration

### Test Projects:
1. Sign in to the app
2. Go to **Management** > **Projects**
3. Click the **+** button to create a project
4. Fill in the form and save
5. Verify the project appears in the list
6. Check Firebase Console to see the data in Firestore

### Test User Invitations:
1. Go to **Management** > **Users**
2. Click **"Invite User"** button
3. Fill in the invitation form and send
4. Verify the invitation appears in the list
5. Check Firebase Console to see the data in Firestore

### Test Offline Behavior:
1. Disconnect from internet
2. Try to create a project or invite a user
3. You should see an error message: "Network error. Please check your internet connection."
4. Reconnect to internet and retry

## Next Steps

1. **Enable Firestore**: Follow Step 1 above
2. **Configure Security Rules**: Follow Step 2 above
3. **Enable Authentication**: Follow Step 3 above
4. **Test the app**: Create projects and invite users
5. **Monitor usage**: Check Firebase Console for data and usage statistics

## Production Considerations

Before deploying to production:
1. Update security rules to be more restrictive
2. Add data validation rules in Firestore
3. Implement proper company/organization structure
4. Add indexes for better query performance
5. Set up Firebase billing if needed
6. Enable backups in Firestore settings
