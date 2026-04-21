import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../core/models/staff_user_model.dart';
import '../../../core/services/staff_auth_service.dart';

enum AuthGate { loading, signedOut, notStaff, mfaEnrollmentNeeded, ready }

class StaffAuthController extends GetxController {
  final _svc = StaffAuthService.instance;

  final Rx<AuthGate> gate = AuthGate.loading.obs;
  final Rxn<StaffUser> staffUser = Rxn<StaffUser>();
  final Rxn<User> firebaseUser = Rxn<User>();

  MultiFactorResolver? pendingMfaResolver;

  @override
  void onInit() {
    super.onInit();
    _svc.authStateChanges().listen(_onAuthChanged);
    // Route on gate changes regardless of which screen is mounted.
    // Previously the routing lived in the _AuthGate widget at '/', which only
    // fired when that widget was actively rebuilding — leaving the app stuck
    // on /mfa-challenge after a successful challenge.
    ever<AuthGate>(gate, _handleGateChange);
  }

  void _handleGateChange(AuthGate g) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final current = Get.currentRoute;
      switch (g) {
        case AuthGate.loading:
          return;
        case AuthGate.signedOut:
          if (current != '/login') Get.offAllNamed('/login');
          return;
        case AuthGate.notStaff:
          if (current != '/access-denied') Get.offAllNamed('/access-denied');
          return;
        case AuthGate.mfaEnrollmentNeeded:
          if (current != '/mfa-enroll') Get.offAllNamed('/mfa-enroll');
          return;
        case AuthGate.ready:
          // If on any unauthed/auth-step screen, route to /home. Otherwise
          // leave the user where they are (e.g. /customers, /customers/:id).
          const preAuthRoutes = {
            '/',
            '/login',
            '/mfa-challenge',
            '/mfa-enroll',
            '/access-denied',
          };
          if (preAuthRoutes.contains(current)) {
            Get.offAllNamed('/home');
          }
          return;
      }
    });
  }

  Future<void> _onAuthChanged(User? user) async {
    firebaseUser.value = user;
    if (user == null) {
      staffUser.value = null;
      gate.value = AuthGate.signedOut;
      return;
    }

    gate.value = AuthGate.loading;
    final doc = await _svc.fetchStaffUserDoc(user.uid);

    if (doc == null || !doc.isStaff || doc.disabled) {
      await _svc.signOut();
      gate.value = AuthGate.notStaff;
      return;
    }
    staffUser.value = doc;

    final enrolledFactors = await user.multiFactor.getEnrolledFactors();
    if (enrolledFactors.isEmpty) {
      gate.value = AuthGate.mfaEnrollmentNeeded;
      return;
    }

    if (!doc.mfaEnrolled) {
      await _svc.markMfaEnrolled(user.uid);
    }

    gate.value = AuthGate.ready;
  }

  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _svc.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthMultiFactorException catch (e) {
      pendingMfaResolver = e.resolver;
      Get.offAllNamed('/mfa-challenge');
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid. [${e.code}]';
      case 'user-disabled':
        return 'This account has been disabled. [${e.code}]';
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Email or password is incorrect. [${e.code}]';
      case 'too-many-requests':
        return 'Too many failed attempts. Try again later. [${e.code}]';
      default:
        final msg = e.message ?? '(no message)';
        return '$msg [${e.code}]';
    }
  }

  Future<void> signOut() async {
    await _svc.signOut();
  }
}
