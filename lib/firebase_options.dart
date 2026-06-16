// Atlas Firebase configuration — env-aware.
//
// Atlas shares Firebase projects with the customer PagentZ app — there are
// no separate "Atlas" Firebase projects. We reuse the same web-app
// registrations the customer-app's firebase_options_*.dart files use so
// both apps hit the same Auth, Firestore, and Cloud Functions per env.
//
// The selected env at build time comes from AppConfig.env, which reads
// the `--dart-define=ENV=...` value.
//
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/config/app_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb) {
      throw UnsupportedError(
        'Atlas is web-only. Run with: flutter run -d chrome',
      );
    }
    switch (AppConfig.env) {
      case 'prod':
        return _prodOptions;
      case 'staging':
        return _stagingOptions;
      default:
        return _devOptions;
    }
  }

  // ── DEV (pagentz) ──────────────────────────────────────────────────────────
  // Same web app as customer-app dev (PAGENTZDEV-ramadev/lib/firebase_options_dev.dart).
  static const FirebaseOptions _devOptions = FirebaseOptions(
    apiKey: 'AIzaSyBc4CjsXMAcIPjgk8e8T_MEJgs1WWMx6Uw',
    appId: '1:691991294097:web:ed8e46f31bdeb47a1a0f30',
    messagingSenderId: '691991294097',
    projectId: 'pagentz',
    authDomain: 'pagentz.firebaseapp.com',
    storageBucket: 'pagentz.firebasestorage.app',
    measurementId: 'G-HMEBST3EML',
  );

  // ── STAGING (pagentz-staging) ──────────────────────────────────────────────
  // Same web app as customer-app staging (firebase_options_staging.dart).
  static const FirebaseOptions _stagingOptions = FirebaseOptions(
    apiKey: 'AIzaSyAlkY4rH1BB44N5O28hp8V3wg6l1gqEarQ',
    appId: '1:301806333927:web:437a49d9aa55bb09811742',
    messagingSenderId: '301806333927',
    projectId: 'pagentz-staging',
    authDomain: 'pagentz-staging.firebaseapp.com',
    storageBucket: 'pagentz-staging.firebasestorage.app',
    measurementId: 'G-JDT53G3MZG',
  );

  // ── PRODUCTION (pagentz-production) ────────────────────────────────────────
  // Same web app as customer-app prod (firebase_options_prod.dart).
  static const FirebaseOptions _prodOptions = FirebaseOptions(
    apiKey: 'AIzaSyAb-XjV48nWfggMYGfTZDM3gMYcUIgZNZ4',
    appId: '1:584777677575:web:3f847d8634f7b08e3c23a2',
    messagingSenderId: '584777677575',
    projectId: 'pagentz-production',
    authDomain: 'pagentz-production.firebaseapp.com',
    storageBucket: 'pagentz-production.firebasestorage.app',
    measurementId: 'G-K1BLDJ8SKV',
  );
}
