import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/atlas_config.dart';
import '../../modules/auth/controller/staff_auth_controller.dart';

/// Enforces two timeouts client-side:
///   * Idle timeout (AtlasConfig.idleTimeout, default 30 min of inactivity)
///   * Session timeout (AtlasConfig.sessionTimeout, default 8h hard cap)
///
/// On either trigger, the staff user is signed out. Notified on sign-in via
/// [startForNewSession] from the auth controller; reset on any user input.
class SessionTimeoutService extends GetxController {
  static SessionTimeoutService get instance =>
      Get.put(SessionTimeoutService(), permanent: true);

  Timer? _idleTimer;
  Timer? _sessionTimer;
  DateTime? _sessionStartedAt;

  void startForNewSession() {
    _sessionStartedAt = DateTime.now();
    _armIdle();
    _armSession();
  }

  void clear() {
    _idleTimer?.cancel();
    _sessionTimer?.cancel();
    _idleTimer = null;
    _sessionTimer = null;
    _sessionStartedAt = null;
  }

  /// Call on every user input event to keep the idle timer alive.
  void touch() {
    if (_sessionStartedAt == null) return;
    _armIdle();
  }

  void _armIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(AtlasConfig.idleTimeout, () {
      _fireTimeout('idle');
    });
  }

  void _armSession() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(AtlasConfig.sessionTimeout, () {
      _fireTimeout('session');
    });
  }

  Future<void> _fireTimeout(String kind) async {
    clear();
    final c = Get.find<StaffAuthController>();
    await c.signOut();
    // Show a snackbar after sign-out routing completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        kind == 'idle' ? 'Signed out — idle' : 'Signed out — session expired',
        kind == 'idle'
            ? 'You were signed out after ${AtlasConfig.idleTimeout.inMinutes} min of inactivity.'
            : 'Your session reached the ${AtlasConfig.sessionTimeout.inHours}-hour maximum.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 6),
      );
    });
  }
}
