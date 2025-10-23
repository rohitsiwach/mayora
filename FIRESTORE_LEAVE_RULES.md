# Firestore Rules for Leave Management

Add these rules to your `firestore.rules` file:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ... existing rules ...
    
    // Leave Requests Collection
    match /leave_requests/{requestId} {
      // Allow users to read their own leave requests
      allow read: if request.auth != null && 
                     (resource.data.userId == request.auth.uid || 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'manager']);
      
      // Allow users to create their own leave requests
      allow create: if request.auth != null && 
                       request.resource.data.userId == request.auth.uid &&
                       request.resource.data.organizationId is string &&
                       request.resource.data.leaveTypeId is string &&
                       request.resource.data.startDate is timestamp &&
                       request.resource.data.endDate is timestamp &&
                       request.resource.data.numberOfDays is number &&
                       request.resource.data.reason is string &&
                       request.resource.data.status == 'pending' &&
                       request.resource.data.createdAt is timestamp;
      
      // Allow users to cancel their own pending requests
      allow update: if request.auth != null && 
                       resource.data.userId == request.auth.uid &&
                       resource.data.status == 'pending' &&
                       request.resource.data.status == 'cancelled';
      
      // Allow admins/managers to update any leave request (approve/reject)
      allow update: if request.auth != null && 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'manager'] &&
                       request.resource.data.status in ['approved', 'rejected'] &&
                       request.resource.data.reviewedBy == request.auth.uid &&
                       request.resource.data.reviewedAt is timestamp;
      
      // Prevent deletion of leave requests (for audit trail)
      allow delete: if false;
    }
  }
}
```

## Rule Explanation

### Read Access
- Users can read their own leave requests (userId matches auth.uid)
- Admins and managers can read all leave requests in the organization

### Create Access
- Users can only create leave requests for themselves
- Required fields validation:
  - userId must match authenticated user
  - organizationId, leaveTypeId must be strings
  - startDate, endDate must be timestamps
  - numberOfDays must be a number
  - reason must be a string
  - status must be 'pending' on creation
  - createdAt must be a timestamp

### Update Access
Two scenarios allowed:
1. **User Cancellation**: Users can cancel their own pending requests
   - Must be the request owner
   - Status must be 'pending'
   - Can only change status to 'cancelled'

2. **Admin/Manager Review**: Admins and managers can approve or reject requests
   - Must have admin or manager role
   - Can only set status to 'approved' or 'rejected'
   - Must include reviewedBy (their user ID)
   - Must include reviewedAt timestamp

### Delete Access
- Deletion is disabled to maintain audit trail

## How to Deploy

1. Open Firebase Console: https://console.firebase.google.com
2. Select your project
3. Go to Firestore Database > Rules
4. Add the leave_requests rules to your existing rules
5. Click "Publish"

## Testing Rules

You can test these rules in the Firebase Console:
1. Go to Firestore Database > Rules
2. Click on "Rules Playground"
3. Test different scenarios:
   - User creating their own request
   - User reading their own requests
   - Admin approving a request
   - User trying to approve their own request (should fail)
