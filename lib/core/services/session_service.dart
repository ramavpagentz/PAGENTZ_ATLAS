import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../config/app_config.dart';
import '../../modules/auth/controller/auth_controller.dart';
import '../../theme/atlas_colors.dart';
import '../../utils/routes.dart';

/// Tracks staff session lifetime and idle activity. Auto-logs out on:
///   - 30 min of no input (idle timeout)
///   - 8 hours since sign-in (hard session timeout)
class SessionService {
  SessionService._();
  static final instance = SessionService._();

  DateTime? _sessionStart;
  DateTime _lastActivity = DateTime.now();
  Timer? _ticker;
  bool _warningShown = false;

  void start() {
    _sessionStart = DateTime.now();
    _lastActivity = DateTime.now();
    _warningShown = false;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null;
    _sessionStart = null;
  }

  /// Called from the activity wrapper on every user event.
  void noteActivity() {
    _lastActivity = DateTime.now();
    if (_warningShown) {
      _warningShown = false;
      // dismiss any open warning snackbar
      if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    }
  }

  void _check() {
    final now = DateTime.now();

    // Hard session timeout
    if (_sessionStart != null &&
        now.difference(_sessionStart!) > AppConfig.sessionTimeout) {
      _forceSignOut(reason: 'session_expired');
      return;
    }

    // Idle timeout — show warning at -2 min, log out at zero
    final idleFor = now.difference(_lastActivity);
    final remaining = AppConfig.idleTimeout - idleFor;

    if (remaining.isNegative) {
      _forceSignOut(reason: 'idle');
      return;
    }
    if (remaining.inSeconds <= 120 && !_warningShown) {
      _warningShown = true;
      _showIdleWarning(remaining);
    }
  }

  void _showIdleWarning(Duration remaining) {
    Get.snackbar(
      'You\'ll be signed out soon',
      'Move the mouse or press a key to stay signed in. ${remaining.inSeconds}s remaining.',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 110),
      backgroundColor: AtlasColors.warningSoft,
      colorText: AtlasColors.warning,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.timer_outlined, color: AtlasColors.warning),
    );
  }

  Future<void> _forceSignOut({required String reason}) async {
    stop();
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    if (Get.isRegistered<AuthController>()) {
      await Get.find<AuthController>().signOut();
    }
    Get.offAllNamed(AtlasRoutes.login);
    Get.snackbar(
      reason == 'idle' ? 'Signed out due to inactivity' : 'Session expired',
      reason == 'idle'
          ? 'For your security, Atlas signed you out after ${AppConfig.idleTimeout.inMinutes} minutes idle.'
          : 'Maximum session length is ${AppConfig.sessionTimeout.inHours} hours. Please sign in again.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AtlasColors.dangerSoft,
      colorText: AtlasColors.danger,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 6),
    );
  }
}

/// Wraps the app and forwards every user input event to [SessionService.noteActivity].
class SessionActivityWrapper extends StatefulWidget {
  final Widget child;
  const SessionActivityWrapper({super.key, required this.child});

  @override
  State<SessionActivityWrapper> createState() => _SessionActivityWrapperState();
}

class _SessionActivityWrapperState extends State<SessionActivityWrapper> {
  bool _onKey(KeyEvent event) {
    SessionService.instance.noteActivity();
    return false; // don't consume the event
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => SessionService.instance.noteActivity(),
      onPointerMove: (_) => SessionService.instance.noteActivity(),
      onPointerSignal: (_) => SessionService.instance.noteActivity(),
      child: widget.child,
    );
  }
}
