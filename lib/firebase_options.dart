// Firebase configuration for Atlas — same project as the main PagentZ app.
// If you later run `flutterfire configure` in Atlas, it will regenerate this
// file automatically.
//
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'Atlas is web-only. Run with: flutter run -d chrome',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBc4CjsXMAcIPjgk8e8T_MEJgs1WWMx6Uw',
    appId: '1:691991294097:web:ed8e46f31bdeb47a1a0f30',
    messagingSenderId: '691991294097',
    projectId: 'pagentz',
    authDomain: 'pagentz.firebaseapp.com',
    storageBucket: 'pagentz.firebasestorage.app',
    measurementId: 'G-HMEBST3EML',
  );
}
