# Mayora

A cross-platform Flutter application supporting Android, iOS, and web platforms with a beautiful swirl logo design.

## Features

- ✅ Cross-platform support (Android, iOS, Web)
- ✅ Beautiful swirl logo integration throughout the app
- ✅ Animated splash screen with logo
- ✅ **Firebase Authentication** with email/password
- ✅ **User Sign In/Sign Up** pages with form validation
- ✅ **Authentication state management** with auto-redirect
- ✅ **Sign out functionality** with confirmation
- ✅ **Password reset** via email
- ✅ Material Design 3 UI with custom branding
- ✅ Responsive design for web
- ✅ Modern Flutter architecture
- ✅ Hero animations and smooth transitions
- ✅ **User Management System** with user groups
- ✅ **Project Management** capabilities
- ✅ **Organization-scoped data** with Firestore

## Authentication Features

The Mayora app includes a complete authentication system:

### Sign In Page
- Email and password authentication
- Form validation with error messages
- Password visibility toggle
- Forgot password functionality
- Beautiful gradient background with logo
- Loading states and error handling

### Sign Up Page
- User registration with email and password
- Full name collection and display name setting
- Password confirmation validation
- Terms of service agreement checkbox
- Account creation with automatic sign-in

### Authentication Flow
- **Default page**: Sign-in page when not authenticated
- **Mock homepage**: Dashboard with cards when authenticated  
- Authentication state-based routing
- Persistent login sessions
- Secure sign out with complete session cleanup

## User Management Features

The Mayora app includes a comprehensive user management system:

### User Groups System
- **Multi-Tab Interface**: Users, Invitations, and User Groups
- **Group Management**: Create, edit, and delete user groups
- **Member Management**: Add and remove users from groups
- **Real-time Updates**: Live synchronization using Firebase streams
- **Organization Scoping**: All data isolated per organization

### User Invitation System
- **Invitation Codes**: Generate unique codes for new users
- **Email Invitations**: Send invitations via email
- **Role Assignment**: Set access levels (Admin, Manager, Employee)
- **Department & Position**: Assign users to departments and roles
- **Payment Information**: Track monthly/hourly compensation

### Access Control
- **Multi-level Permissions**: Admin, Manager, Manager Read Only, Employee
- **Organization Isolation**: Users only see their organization's data
- **Secure Authentication**: Firebase-based user management

## Logo Integration

The Mayora app features a beautiful gradient swirl logo that appears in multiple places:

- **Splash Screen**: Animated logo with fade and scale transitions
- **App Bar**: Small logo in the navigation bar
- **Home Screen**: Large hero logo in the center
- **About Page**: Detailed logo showcase with app information
- **Navigation Drawer**: Logo in the drawer header
- **App Icons**: Custom app icons for all platforms

### Logo Assets

Place your logo files in the `assets/images/` directory:
- `mayora_logo.png` - Main logo (120x120 recommended)
- `mayora_logo_small.png` - Small version (64x64)
- `mayora_logo_large.png` - Large version (256x256)

## Color Scheme

The app uses a gradient color scheme inspired by the logo:
- Primary: `#673AB7` (Deep Purple)
- Secondary: `#9C27B0` (Purple)
- Accent: `#00BCD4` (Cyan)

## Getting Started

### Prerequisites

- Flutter SDK (3.35.4 or later)
- Dart SDK (3.9.2 or later)
- Android Studio (for Android development)
- Xcode (for iOS development - macOS only)
- Chrome browser (for web development)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. **Configure Firebase** (Ready for Web!):
   - ✅ Firebase project: `mayora-160cf` configured
   - ✅ Web authentication ready to test
   - ⚠️ **Required**: Enable Email/Password in Firebase Console
   - 📖 Follow setup guide in `FIREBASE_SETUP.md`

### Running the App

#### Development Mode
```bash
flutter run
```

#### Web Platform
```bash
flutter run -d chrome
```

#### Android Platform
```bash
flutter run -d android
```

#### iOS Platform (macOS only)
```bash
flutter run -d ios
```

### Building for Production

#### Web Build
```bash
flutter build web
```

#### Android APK
```bash
flutter build apk
```

#### iOS Build (macOS only)
```bash
flutter build ios
```

### VS Code Tasks

This project includes VS Code tasks for common Flutter operations:
- **Flutter: Run** - Run the app in development mode
- **Flutter: Run Web** - Run the app in Chrome
- **Flutter: Build Web** - Build for web deployment
- **Flutter: Build APK** - Build Android APK
- **Flutter: Test** - Run unit tests

Access these tasks via `Ctrl+Shift+P` > "Tasks: Run Task"

## Project Structure

```
lib/
  ├── main.dart          # App entry point
test/
  ├── widget_test.dart   # Widget tests
web/                     # Web-specific files
android/                 # Android-specific files
ios/                     # iOS-specific files
```

## Development Guidelines

- Follow Flutter best practices and conventions
- Use Material Design principles for UI consistency
- Ensure responsive design for web platform
- Test across all target platforms
- Keep dependencies up to date

## Testing

Run unit tests:
```bash
flutter test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design](https://material.io/design)

## Data maintenance: Merge duplicate user docs

If you ever end up with two user documents for the same person (for example, one document with profile fields and another that has `leaves/` and `schedules/` subcollections), you can merge them into a single canonical doc using the script in `scripts/`.

Canonical convention: the user document ID should be the Firebase Auth UID.

### Steps (Windows PowerShell)

1) Install Node deps for the script

```powershell
cd scripts
npm install
```

2) Authenticate Admin SDK (choose one)

- Use Application Default Credentials via gcloud:

```powershell
gcloud auth application-default login
```

- Or set a service account key file:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\\path\\to\\service-account.json"
```

3) Run the merge

```powershell
# Syntax
npm run merge-user -- <SOURCE_USER_ID> <TARGET_USER_ID> [--dry-run] [--no-delete]

# Example (copy everything from source -> target and delete source afterwards)
npm run merge-user -- Wq4GEPHEpw5xHCldqJfC HJkd7luti8gadiikYvk5KLlOVXm1

# Example dry run (no writes)
npm run merge-user -- Wq4GEPHEpw5xHCldqJfC HJkd7luti8gadiikYvk5KLlOVXm1 --dry-run

# Keep the source doc and its subcollections (no deletion)
npm run merge-user -- Wq4GEPHEpw5xHCldqJfC HJkd7luti8gadiikYvk5KLlOVXm1 --no-delete
```

What it does:
- Merges top-level fields from source into target using `{ merge: true }`
- Copies all subcollections (including `leaves/` and `schedules/`) from source to target
- Normalizes `userId` field in copied data to the target ID
- Optionally deletes the source subcollections and source document (omit with `--no-delete`)

After merging, update any app code that creates users to always write to `users/{auth.uid}` to prevent duplicates.
