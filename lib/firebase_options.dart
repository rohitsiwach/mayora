import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC5A2k5yOR7siB6R8HPkjxSouR0tmqy0EM',
    appId: '1:mayora-160cf:web:your-web-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'mayora-160cf',
    authDomain: 'mayora-160cf.firebaseapp.com',
    storageBucket: 'mayora-160cf.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your-android-api-key',
    appId: '1:mayora-160cf:android:your-android-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'mayora-160cf',
    storageBucket: 'mayora-160cf.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your-ios-api-key',
    appId: '1:mayora-160cf:ios:your-ios-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'mayora-160cf',
    storageBucket: 'mayora-160cf.appspot.com',
    iosBundleId: 'com.example.mayora',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'your-macos-api-key',
    appId: '1:mayora-160cf:macos:your-macos-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'mayora-160cf',
    storageBucket: 'mayora-160cf.appspot.com',
    iosBundleId: 'com.example.mayora',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC5A2k5yOR7siB6R8HPkjxSouR0tmqy0EM',
    appId: '1:mayora-160cf:windows:your-windows-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'mayora-160cf',
    authDomain: 'mayora-160cf.firebaseapp.com',
    storageBucket: 'mayora-160cf.appspot.com',
  );
}
