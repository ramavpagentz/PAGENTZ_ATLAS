import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';
import '../models/staff_user_model.dart';
import 'audit_log_service.dart';

class StaffSignInResult {
  final bool success;
  final StaffUser? staff;
  final String? errorMessage;

  const StaffSignInResult.ok(this.staff)
      : success = true,
        errorMessage = null;
  const StaffSignInResult.failed(this.errorMessage)
      : success = false,
        staff = null;
}

/// Email/password auth for Atlas staff.
///
/// On first sign-in attempt with the bootstrap admin credentials
/// (admin@pagentz.com / atlas@2026), the admin account is auto-created.
/// After that, admins can create additional staff from the Staff Management
/// screen (which uses the `atlasCreateStaffAccount` Cloud Function).
class StaffAuthService {
  StaffAuthService._();
  static final instance = StaffAuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<StaffSignInResult> signInWithEmail(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Bootstrap path: if this is the default admin and the account doesn't
    // exist yet, create it on the fly.
    if (normalizedEmail == AppConfig.bootstrapAdminEmail &&
        password == AppConfig.bootstrapAdminPassword) {
      final bootstrap = await _ensureBootstrapAdmin();
      if (bootstrap != null) return bootstrap;
    }

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      return _validateStaff(cred.user);
    } on FirebaseAuthException catch (e) {
      return StaffSignInResult.failed(_friendlyAuthError(e));
    } catch (e) {
      return StaffSignInResult.failed(e.toString());
    }
  }

  /// Creates the bootstrap admin account if it doesn't already exist.
  /// Returns a sign-in result if bootstrap ran (whether it succeeded or not),
  /// or null to signal "fall through to normal sign-in".
  Future<StaffSignInResult?> _ensureBootstrapAdmin() async {
    try {
      // Try sign-in first — if it works, the account already exists.
      final cred = await _auth.signInWithEmailAndPassword(
        email: AppConfig.bootstrapAdminEmail,
        password: AppConfig.bootstrapAdminPassword,
      );
      // Ensure the Firestore doc has Atlas fields (may be missing if the
      // account existed before Atlas was deployed).
      if (cred.user != null) {
        await _db.collection('users').doc(cred.user!.uid).set({
          'email': AppConfig.bootstrapAdminEmail,
          'displayName': AppConfig.bootstrapAdminName,
          'isAtlas': true,
          'staffRole': StaffRole.owner.id,
          'mfaEnrolled': false,
          'disabled': false,
        }, SetOptions(merge: true));
      }
      return _validateStaff(cred.user);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'user-not-found' && e.code != 'invalid-credential') {
        return StaffSignInResult.failed(_friendlyAuthError(e));
      }
      // Fall through to create-the-admin path below.
    } catch (e) {
      // On web, Firebase may throw a generic Exception instead of
      // FirebaseAuthException. Check the message for known codes.
      final msg = e.toString();
      if (msg.contains('user-not-found') || msg.contains('invalid-credential')) {
        // Fall through to create-the-admin path below.
      } else {
        return StaffSignInResult.failed(msg);
      }
    }

    // Create the account
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: AppConfig.bootstrapAdminEmail,
        password: AppConfig.bootstrapAdminPassword,
      );
      final uid = cred.user!.uid;
      await _db.collection('users').doc(uid).set({
        'email': AppConfig.bootstrapAdminEmail,
        'displayName': AppConfig.bootstrapAdminName,
        'isAtlas': true,
        'staffRole': StaffRole.owner.id,
        'mfaEnrolled': false,
        'disabled': false,
        'staffJoinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await cred.user!.updateDisplayName(AppConfig.bootstrapAdminName);
      return _validateStaff(cred.user);
    } on FirebaseAuthException catch (e) {
      return StaffSignInResult.failed(_friendlyAuthError(e));
    } catch (e) {
      return StaffSignInResult.failed(e.toString());
    }
  }

  /// After Firebase auth succeeds, load the Firestore user doc and confirm
  /// isAtlas:true. Sign them out if not.
  Future<StaffSignInResult> _validateStaff(User? user) async {
    if (user == null) {
      return const StaffSignInResult.failed('Sign in failed.');
    }

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        return const StaffSignInResult.failed(
          'Access denied. This site is for Atlas staff only.',
        );
      }

      final staff = StaffUser.fromFirestore(doc);
      if (!staff.canAccessAtlas) {
        await _auth.signOut();
        return const StaffSignInResult.failed(
          'Access denied. This site is for Atlas staff only.',
        );
      }

      await _db.collection('users').doc(user.uid).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AuditLogService.instance.setCurrentStaff(staff);
      await AuditLogService.instance.log(
        action: 'LOGIN_SUCCESS',
        targetType: 'staff',
        targetId: staff.uid,
        targetDisplay: staff.email,
      );

      return StaffSignInResult.ok(staff);
    } catch (e) {
      await _auth.signOut();
      return StaffSignInResult.failed(e.toString());
    }
  }

  Future<StaffUser?> loadCurrentStaff() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        return null;
      }
      final staff = StaffUser.fromFirestore(doc);
      if (!staff.canAccessAtlas) {
        await _auth.signOut();
        return null;
      }
      AuditLogService.instance.setCurrentStaff(staff);
      return staff;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This staff account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again in a few minutes.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Sign in failed (${e.code}).';
    }
  }
}
