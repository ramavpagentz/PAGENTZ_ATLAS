// Atlas Firebase configuration — env-aware.
//
// One DefaultFirebaseOptions class with a static `currentPlatform` getter
// that picks the right [FirebaseOptions] block based on AppConfig.env.
//
// Steps to populate staging + prod blocks:
//   1. Firebase Console → Pagentz Staging → Project Settings →
//      "Your apps" → add Web app (nickname: "Atlas (staging)") →
//      copy appId + apiKey + measurementId into _stagingOptions below.
//   2. Same for Pagentz Production → "Atlas (prod)" → _prodOptions.
//
// Until those web apps exist the staging/prod options use the same project's
// known constants (projectId, messagingSenderId, authDomain, storageBucket)
// but appId + apiKey MUST be replaced or Firebase init will fail at runtime.
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
  // Current pre-Option-C config. Kept for local dev / fallback.
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
  // TODO(env-rollout): replace appId + apiKey + measurementId with the values
  // from the Atlas web app you register on pagentz-staging.
  static const FirebaseOptions _stagingOptions = FirebaseOptions(
    apiKey: 'REPLACE_WITH_STAGING_WEB_API_KEY',
    appId: 'REPLACE_WITH_STAGING_WEB_APP_ID',
    messagingSenderId: '301806333927',
    projectId: 'pagentz-staging',
    authDomain: 'pagentz-staging.firebaseapp.com',
    storageBucket: 'pagentz-staging.firebasestorage.app',
    measurementId: 'REPLACE_WITH_STAGING_MEASUREMENT_ID',
  );

  // ── PRODUCTION (pagentz-production) ────────────────────────────────────────
  // TODO(env-rollout): replace appId + apiKey + measurementId with the values
  // from the Atlas web app you register on pagentz-production.
  static const FirebaseOptions _prodOptions = FirebaseOptions(
    apiKey: 'REPLACE_WITH_PROD_WEB_API_KEY',
    appId: 'REPLACE_WITH_PROD_WEB_APP_ID',
    messagingSenderId: '584777677575',
    projectId: 'pagentz-production',
    authDomain: 'pagentz-production.firebaseapp.com',
    storageBucket: 'pagentz-production.firebasestorage.app',
    measurementId: 'REPLACE_WITH_PROD_MEASUREMENT_ID',
  );
}
