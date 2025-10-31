# Fix: Account Already Exists Error During Invitation Signup

## Problem
When a user tried to accept an invitation with an email that already had a Firebase Auth account, the app showed "account already exists" error but didn't properly catch it. The issue was that `fetchSignInMethodsForEmail()` is deprecated and doesn't reliably detect existing accounts.

## Solution Implemented
Replaced the deprecated pre-check approach with a direct try-catch approach when creating the account:

### Before (lines 114-150)
```dart
// Check if an account already exists for this email
final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(invitedEmail);
final exists = methods.isNotEmpty;
if (exists) {
  // Show dialog...
  return;
}

// Create authentication account since none exists
final userCredential = await _authService.createUserWithEmailAndPassword(
  email: invitedEmail,
  password: _passwordController.text,
);
```

### After (lines 114-158)
```dart
// Try to create the authentication account
try {
  final userCredential = await _authService.createUserWithEmailAndPassword(
    email: invitedEmail,
    password: _passwordController.text,
  );

  if (userCredential == null) {
    throw Exception('Failed to create account');
  }
  userId = userCredential.user!.uid;
} on FirebaseAuthException catch (authError) {
  if (authError.code == 'email-already-in-use') {
    // Account exists - guide user to sign in instead
    if (mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Account already exists'),
          content: Text(
            'An account with $invitedEmail already exists.\n\n'
            'Please sign in with that account to accept this invitation. After signing in, '
            'return to this page and tap "Complete Registration".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.pushNamed(context, '/');
              },
              child: const Text('Go to Sign In'),
            ),
          ],
        ),
      );
    }
    return; // stop here; user will sign in and retry
  }
  // Re-throw other auth errors
  rethrow;
}
```

## Changes Made
1. **Removed deprecated API**: Eliminated `fetchSignInMethodsForEmail()` call
2. **Added proper exception handling**: Wrapped `createUserWithEmailAndPassword()` in try-catch
3. **Specific error detection**: Catches `FirebaseAuthException` with code `'email-already-in-use'`
4. **Proper error propagation**: Re-throws other auth errors to be handled by outer catch block

## Benefits
- **More reliable**: Catches the actual error from Firebase Auth instead of relying on deprecated pre-check
- **Better user experience**: Shows clear guidance dialog when account exists
- **Future-proof**: Uses current Firebase Auth API patterns
- **Cleaner code**: Single operation instead of check-then-create pattern

## Testing
- ✅ Compiles without errors
- ✅ Formatted with `dart format`
- ✅ Web build successful

## User Flow When Account Exists
1. User enters invitation code and password
2. App tries to create account with Firebase Auth
3. Firebase returns `email-already-in-use` error
4. Dialog appears: "Account already exists"
5. User clicks "Go to Sign In"
6. User signs in with existing credentials
7. User returns to invitation page
8. User clicks "Complete Registration"
9. Since user is now authenticated, the `if (current != null && ...)` branch handles linking invitation

## Files Modified
- `lib/pages/invitation_signup_page.dart` (lines 114-158)
