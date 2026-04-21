import 'package:flutter/material.dart';

class AtlasConfig {
  AtlasConfig._();

  static const String firebaseProjectId = 'pagentz';
  static const String staffTenantId = 'Atlas-Staff-2o08x';
  static const String hostingSiteId = 'atlas-13fd3';
  static const String atlasDomain = 'atlas.pagentz.com';
  static const String productName = 'PagentZ Atlas';

  static const String mfaIssuer = 'PagentZ Atlas';
  static const Duration idleTimeout = Duration(minutes: 30);
  static const Duration sessionTimeout = Duration(hours: 8);

  static const Color primarySeed = Color(0xFF6366F1);
}
