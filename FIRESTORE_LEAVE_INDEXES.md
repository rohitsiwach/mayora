# Firestore Indexes for Leave Management

The leave management feature requires the following composite indexes in Firestore for efficient querying.

## Required Indexes

### Index 1: User Leave Requests (Ordered by Creation Date)
Used by: `LeaveService.getUserLeaveRequests()`

**Collection**: `leave_requests`

**Fields**:
1. `userId` (Ascending)
2. `createdAt` (Descending)

**Query Scope**: Collection

**Purpose**: Fetch all leave requests for a specific user, ordered by most recent first.

---

### Index 2: Organization Leave Requests (Ordered by Creation Date)
Used by: `LeaveService.getOrganizationLeaveRequests()`

**Collection**: `leave_requests`

**Fields**:
1. `organizationId` (Ascending)
2. `createdAt` (Descending)

**Query Scope**: Collection

**Purpose**: Fetch all leave requests for an organization (for admins/managers), ordered by most recent first.

---

### Index 3: User Leave Type Status Query (for Balance Calculation)
Used by: `LeaveService.getUsedLeaveDays()`

**Collection**: `leave_requests`

**Fields**:
1. `userId` (Ascending)
2. `leaveTypeId` (Ascending)
3. `status` (Ascending)
4. `startDate` (Ascending)

**Query Scope**: Collection

**Purpose**: Calculate used leave days for a specific user and leave type within a date range, filtering by approved status.

---

## How to Create Indexes

### Method 1: Automatic Creation (Recommended)
1. Run the app and trigger the queries that need indexes
2. Watch the Flutter console for Firestore index errors
3. Click the provided URL in the error message
4. Firebase Console will open with the index pre-configured
5. Click "Create Index"

### Method 2: Manual Creation via Firebase Console
1. Open Firebase Console: https://console.firebase.google.com
2. Select your project
3. Go to **Firestore Database** > **Indexes** tab
4. Click **Create Index**
5. For each index above:
   - Set Collection ID: `leave_requests`
   - Add fields in the specified order with correct sort direction
   - Click **Create**

### Method 3: Using Firebase CLI
Create a `firestore.indexes.json` file in your project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "leave_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "leave_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "organizationId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "leave_requests",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "leaveTypeId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "startDate",
          "order": "ASCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Then deploy using:
```bash
firebase deploy --only firestore:indexes
```

---

## Index Build Time

- Indexes typically take 5-15 minutes to build
- Build time depends on existing data in the collection
- For empty collections, indexes build instantly
- You can monitor build progress in Firebase Console under **Firestore Database** > **Indexes**

## Troubleshooting

If you see errors like:
```
The query requires an index. You can create it here: [URL]
```

This means:
1. An index is missing
2. Click the URL to auto-create it
3. Wait for the index to build
4. Try the query again

## Verification

After creating indexes, verify they're active:
1. Go to Firebase Console > Firestore Database > Indexes
2. Check that all indexes show status "Enabled"
3. If status is "Building", wait for completion
4. Test the app functionality that uses these queries
