# Firebase Deployment Guide

This guide explains how to deploy the Firestore security rules for the Mayora application.

## Prerequisites

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

## Deployment Steps

### 1. Initialize Firebase (if not already done)

```bash
firebase init
```

Select:
- Firestore: Configure security rules and indexes files
- Hosting (optional): Configure files for Firebase Hosting

### 2. Deploy Firestore Rules

To deploy only the Firestore security rules:

```bash
firebase deploy --only firestore:rules
```

### 3. Deploy Firestore Indexes

To deploy the Firestore indexes:

```bash
firebase deploy --only firestore:indexes
```

### 4. Deploy Everything

To deploy both rules and indexes:

```bash
firebase deploy --only firestore
```

## Security Rules Overview

The `firestore.rules` file includes security rules for:

### Collections Secured:

1. **users** - User profiles and information
   - Read: Authenticated users in same organization
   - Create: New users during signup
   - Update: Own profile or admin
   - Delete: Admin only

2. **organizations** - Organization data
   - Read: Members of the organization
   - Create: Authenticated users
   - Update/Delete: Admin only

3. **userInvitations** - User invitation management
   - Read: Same organization members
   - Create: Admin only
   - Update: Invited user or admin
   - Delete: Admin only

4. **projects** - Project management
   - Read: Same organization members
   - Create: Authenticated users
   - Update: Admin, creator, or project members
   - Delete: Admin or creator

5. **userGroups** - User group management
   - Read: Same organization members
   - Create: Admin only
   - Update: Admin only (preserves organization ID)
   - Delete: Admin only

6. **tasks** - Task management (future use)
   - Read: Same organization members
   - Create: Authenticated users
   - Update: Admin, assigned user, or creator
   - Delete: Admin or creator

## Key Security Features

- **Organization Isolation**: Users can only access data from their own organization
- **Role-Based Access**: Admin users have elevated permissions
- **Data Validation**: Rules ensure data integrity (e.g., organization ID cannot change)
- **Member Verification**: User groups validate member lists during creation

## Testing Rules

You can test the rules locally using the Firebase Emulator:

```bash
firebase emulators:start --only firestore
```

## Monitoring

After deployment, monitor rule usage in the Firebase Console:
- Firebase Console → Firestore Database → Rules
- Check for denied requests and adjust rules if needed

## Important Notes

⚠️ **Always test rules in development before deploying to production**

⚠️ **Back up your current rules before deploying new ones**

⚠️ **Ensure all users have proper organizationId and role fields set**
