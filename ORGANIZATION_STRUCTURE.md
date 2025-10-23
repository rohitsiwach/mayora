# Organization-Based Multi-Tenancy Implementation

## Overview
The Mayora app now supports multiple organizations with complete data isolation. Each organization has its own set of projects, users, and invitations that are completely separate from other organizations.

## Database Structure

### Collections

#### 1. `organizations`
Stores organization/company information:
- `id` (auto-generated document ID)
- `companyName` (string)
- `streetAddress` (string)
- `city` (string)
- `state` (string)
- `postalCode` (string)
- `country` (string)
- `adminUserId` (string): Firebase Auth UID of the organization admin
- `adminName` (string)
- `adminEmail` (string)
- `adminPhone` (string)
- `status` (string): "Active" | "Suspended"
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

#### 2. `projects`
**Updated** - Now includes `organizationId`:
- `organizationId` (string): Links project to organization
- `projectName` (string)
- `projectType` (string): "Internal" | "External"
- `billableToClient` (boolean)
- `clientName`, `clientEmail`, `clientPhone` (optional)
- `paymentType`, `lumpSumAmount`, `monthlyRate`, `hourlyRate` (optional)
- `location` (string)
- `description` (string)
- `createdBy` (string): User ID who created the project
- `createdAt`, `updatedAt` (timestamp)

#### 3. `user_invitations`
**Updated** - Now includes `organizationId`:
- `organizationId` (string): Links invitation to organization
- `invitationCode` (string): 8-character unique code
- `expiryDate` (timestamp): 14 days from creation
- `name`, `email`, `accessLevel`, `department`, `position`
- `paymentType`, `monthlyIncome`, `hourlyRate`
- `hireDate`, `yearlyVacations`
- `status` (string): "Pending" | "Accepted"
- `invitedBy` (string): User ID who sent the invitation
- `invitationCount` (number)
- `createdAt`, `updatedAt` (timestamp)

#### 4. `users`
**Updated** - Now includes `organizationId`:
- `organizationId` (string): Links user to organization
- `userId` (string): Firebase Auth UID
- `name`, `email`, `phone`
- `role` (string): "Admin" | "Manager" | "Employee"
- `status` (string): "Active" | "Deactivated"
- `accessLevel`, `department`, `position`
- `address`, `dateOfBirth`
- `insuranceType`, `insuranceProvider`, `insuranceNumber`
- `bankName`, `iban`, `taxId`
- `invitedBy` (string): User ID who invited this user
- `acceptedAt`, `createdAt`, `updatedAt` (timestamp)

## Key Features

### 1. Organization Creation on Signup
When a new user signs up:
1. ✅ Firebase Auth account is created
2. ✅ New organization document is created with company details
3. ✅ User document is created and linked to organization
4. ✅ **Default internal project is automatically created** with:
   - `projectName`: "Default internal project"
   - `projectType`: "Internal"
   - `billableToClient`: false
   - `clientName`, `clientEmail`, `clientPhone`: null
   - `description`: "default internal project"

### 2. Complete Data Isolation
- ✅ All queries filter by `organizationId`
- ✅ Users can only see data from their own organization
- ✅ No cross-organization data access possible
- ✅ Firestore security rules enforce isolation at database level

### 3. Organization-Scoped Operations

**Projects:**
- `getProjects()`: Returns only projects with matching `organizationId`
- `addProject()`: Automatically adds `organizationId` to new projects
- `updateProject()`: Can only update projects in same organization
- `deleteProject()`: Can only delete projects in same organization

**User Invitations:**
- `sendUserInvitation()`: Automatically adds `organizationId`
- `getUserInvitations()`: Returns only invitations for same organization
- `validateInvitationCode()`: Anyone can validate (for signup)
- `acceptInvitation()`: Creates user in same organization

**Users:**
- `getRegisteredUsers()`: Returns only users in same organization
- Users invited through one organization cannot access another

## Security Rules

The Firestore security rules implement organization-based access control:

```javascript
function getUserOrganization() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.organizationId;
}
```

All read/write operations check that:
1. User is authenticated
2. Resource's `organizationId` matches user's `organizationId`

Exception: Invitation validation allows public read (for signup process)

## Services

### OrganizationService
- `createOrganization()`: Creates new organization
- `createDefaultProject()`: Creates default internal project
- `getOrganization()`: Gets organization by ID
- `updateOrganization()`: Updates organization details
- `getUserOrganizationId()`: Gets user's organization ID
- `addUserToOrganization()`: Links user to organization

### FirestoreService (Updated)
- `getCurrentUserOrganizationId()`: Gets and caches user's organization ID
- All methods updated to include `organizationId` in queries
- Uses `Stream.asyncExpand()` for organization-scoped streams

## Testing Checklist

1. ✅ Create new organization account via Sign Up
2. ✅ Verify default project is created
3. ✅ Create additional projects - should be linked to organization
4. ✅ Send invitation - should include organizationId
5. ✅ Accept invitation - new user should join same organization
6. ✅ Verify invited user can see organization's projects
7. ✅ Create second organization with different account
8. ✅ Verify first organization's data is not visible to second organization
9. ✅ Verify security rules prevent cross-organization access

## Migration Notes

**For existing data:**
- Existing projects without `organizationId` will not be accessible
- Existing users without `organizationId` cannot query organization data
- Need to run migration script to assign `organizationId` to existing records
- Or delete existing test data and start fresh

## Benefits

1. **Scalability**: Support unlimited organizations in single database
2. **Security**: Complete data isolation between organizations
3. **Simplicity**: Single Firebase project handles all organizations
4. **Cost-effective**: No need for separate databases per organization
5. **Compliance**: Each organization's data is completely separate
