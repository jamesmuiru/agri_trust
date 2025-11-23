// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB8jJ1o8yujq8TLczsVI7b0nyEa1c860SM',
    appId: '1:731139265794:web:481d722d3f56d2384f1e1b',
    messagingSenderId: '731139265794',
    projectId: 'agroconnect-98a55',
    authDomain: 'agroconnect-98a55.firebaseapp.com',
    storageBucket: 'agroconnect-98a55.firebasestorage.app',
    measurementId: 'G-TNLQW11ZXH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB8jJ1o8yujq8TLczsVI7b0nyEa1c860SM',
    appId: '1:731139265794:android:YOUR_APP_ID',
    messagingSenderId: '731139265794',
    projectId: 'agroconnect-98a55',
    storageBucket: 'agroconnect-98a55.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB8jJ1o8yujq8TLczsVI7b0nyEa1c860SM',
    appId: '1:731139265794:ios:YOUR_APP_ID',
    messagingSenderId: '731139265794',
    projectId: 'agroconnect-98a55',
    storageBucket: 'agroconnect-98a55.firebasestorage.app',
    iosBundleId: 'com.example.myapp',
  );
}