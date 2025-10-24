# Firestore Indexes for Leave Management

## Required Composite Indexes

Add these composite indexes to your Firestore project for optimal query performance:

### 1. Collection Group Query Index (leaves)
For querying all leave requests across the organization using collection group:

**Collection ID:** `leaves`
**Query Scope:** Collection group
**Fields:**
- `organizationId` (Ascending)
- `createdAt` (Descending)

**Firebase CLI Command:**
```bash
firebase firestore:indexes --project your-project-id
```

**Index Configuration (firestore.indexes.json):**
```json
{
  "indexes": [
    {
      "collectionGroup": "leaves",
      "queryScope": "COLLECTION_GROUP",
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
    }
  ]
}
```

### 2. Additional Useful Indexes (Optional)

#### Status-based filtering for management dashboard
```json
{
  "collectionGroup": "leaves",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {
      "fieldPath": "organizationId",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "status",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "createdAt",
      "order": "DESCENDING"
    }
  ]
}
```

#### User-specific leave queries (for individual user history)
```json
{
  "collectionGroup": "leaves",
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
}
```

## How to Create Indexes

### Method 1: Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to Firestore Database
4. Click on "Indexes" tab
5. Click "Create Index"
6. Set up the composite index as specified above

### Method 2: Firebase CLI
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Initialize Firestore: `firebase init firestore`
4. Create `firestore.indexes.json` with the configuration above
5. Deploy indexes: `firebase deploy --only firestore:indexes`

### Method 3: Automatic Creation
When you run queries that require these indexes, Firestore will show error messages with direct links to create the required indexes automatically.

## Performance Notes

- The main index (organizationId + createdAt) supports the `getOrganizationLeaveRequests()` method in `LeaveService`
- Individual user queries use the collection path and don't require additional indexes
- Collection group queries are essential for the management dashboard functionality
- Indexes are automatically created for single-field queries

## Monitoring

Monitor index performance in the Firebase Console under:
- Firestore Database > Usage tab
- Performance monitoring for query execution times