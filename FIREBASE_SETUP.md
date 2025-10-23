# Firebase Setup Guide for Mayora

✅ **FIREBASE PROJECT CONFIGURED**: `mayora-160cf`

This guide documents the Firebase configuration for the Mayora app. The basic web configuration has been set up with your project details.

## Current Configuration Status

- ✅ **Project ID**: `mayora-160cf`
- ✅ **Web API Key**: `AIzaSyC5A2k5yOR7siB6R8HPkjxSouR0tmqy0EM`
- ✅ **Auth Domain**: `mayora-160cf.firebaseapp.com`
- ✅ **Storage Bucket**: `mayora-160cf.appspot.com`
- ⚠️ **Missing**: Android and iOS specific configurations

## Quick Start - Enable Authentication

### Step 1: Enable Email/Password Authentication

1. Go to your Firebase Console: https://console.firebase.google.com/u/0/project/mayora-160cf
2. Navigate to **Authentication** > **Sign-in method**
3. Enable **Email/Password** provider:
   - Click on "Email/Password"
   - Toggle "Enable" to ON
   - Click "Save"

### Step 2: Test on Web (Ready Now!)

Your web configuration is complete! Test immediately:

```bash
# Run on web browser
flutter run -d chrome
```

The Mayora app is ready to use with Firebase Authentication once you enable Email/Password in the Firebase Console!

### 1. Enable Authentication in Firebase Console

## Step 2: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a project"
3. Enter project name: `mayora-app` (or your preferred name)
4. Enable Google Analytics (optional)
5. Create project

## Step 3: Enable Authentication

1. In Firebase Console, go to **Authentication** > **Sign-in method**
2. Enable **Email/Password** provider
3. Optionally enable **Email link (passwordless sign-in)**

## Step 4: Configure Firebase for Flutter

Run the FlutterFire configuration command in your project directory:

```bash
# Navigate to your project directory
cd path/to/Mayora

# Configure Firebase
flutterfire configure --project=your-project-id
```

This will:
- Create `firebase_options.dart` with your actual configuration
- Set up platform-specific configuration files
- Configure Android, iOS, and Web automatically

## Step 5: Platform-Specific Configuration

### Android Configuration
The FlutterFire CLI automatically configures Android, but verify:
- `android/app/google-services.json` is created
- `android/app/build.gradle` includes Firebase plugin

### iOS Configuration
The FlutterFire CLI automatically configures iOS, but verify:
- `ios/Runner/GoogleService-Info.plist` is created
- iOS bundle ID matches Firebase project

### Web Configuration
The FlutterFire CLI automatically configures Web, but verify:
- `web/index.html` includes Firebase SDK scripts
- Web app configuration is correct

## Step 6: Update Firebase Options

After running `flutterfire configure`, your `lib/firebase_options.dart` file will be automatically updated with the correct configuration values. The placeholder file will be replaced with actual Firebase project credentials.

## Step 7: Test Authentication

1. Run the app: `flutter run`
2. Try creating a new account
3. Check Firebase Console > Authentication > Users to see registered users

## ⚠️ CRITICAL: Enable Cloud Firestore

The app uses Firestore for data storage. You MUST enable it:

### Step 1: Enable Firestore Database
1. Go to: https://console.firebase.google.com/u/0/project/mayora-160cf/firestore
2. Click **"Create database"** button
3. Select **"Start in test mode"** (for development)
4. Choose Firestore location: **us-central** (or your preferred region)
5. Click **"Enable"**

### Step 2: Set Up Security Rules (REQUIRED)

After creating the database, click on the **"Rules"** tab and replace with these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Projects collection - users can only access their own projects
    match /projects/{projectId} {
      allow read, write: if request.auth != null;
    }
    
    // User invitations - users can only access invitations they created
    match /user_invitations/{invitationId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Note**: These are simplified rules for development. For production, you should add more restrictive rules that check document ownership.

### Step 3: Publish the Rules
Click **"Publish"** to save the security rules.

### Why This Error Occurred
The error `[cloud_firestore/permission-denied] Missing or insufficient permissions` means:
- Firestore is not enabled yet, OR
- Security rules are too restrictive, OR
- You're not authenticated

**Solution**: Follow Steps 1-3 above to enable Firestore with proper security rules.

## Troubleshooting

### Current Error: Permission Denied

**Error Message**: `[cloud_firestore/permission-denied] Missing or insufficient permissions`

**Cause**: Firestore is not enabled or security rules are not configured.

**Solution**:
1. Enable Firestore Database (see Step 1 above)
2. Configure security rules (see Step 2 above)
3. Make sure you're signed in to the app
4. Refresh the app after enabling Firestore

### Common Issues:

1. **Firestore permission errors**: 
   - Enable Firestore in Firebase Console
   - Set up security rules for `projects` and `user_invitations` collections
   - Ensure you're authenticated in the app

2. **Build failures**: Make sure all platform-specific files are properly configured

3. **Authentication errors**: 
   - Enable Email/Password authentication in Firebase Console
   - Verify Firebase project settings and API keys

4. **Web CORS issues**: Ensure your domain is authorized in Firebase Console

5. **Data not appearing**: 
   - Check security rules are published
   - Verify you're signed in
   - Check browser console for errors

### Firebase Console Locations:
- **Authentication**: Firebase Console > Authentication
- **Project Settings**: Firebase Console > Project Settings > General
- **API Keys**: Firebase Console > Project Settings > Service accounts

## Environment Setup

For production deployments, consider:
1. Setting up different Firebase projects for development/staging/production
2. Using environment-specific configuration files
3. Implementing proper security rules

## Next Steps

After Firebase is configured:
1. Replace placeholder logo files with actual Mayora logo
2. Customize authentication UI to match your brand
3. Add additional authentication providers (Google, Apple, etc.)
4. Implement user profile management
5. Add password strength requirements
6. Set up email verification flows

## Support

For issues with Firebase setup:
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev)
- [Flutter Firebase Authentication](https://firebase.flutter.dev/docs/auth/usage)