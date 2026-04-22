import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../models/staff_user_model.dart';
import 'audit_log_service.dart';

class StaffMutationResult {
  final bool ok;
  final String? errorMessage;
  const StaffMutationResult.success()
      : ok = true,
        errorMessage = null;
  const StaffMutationResult.failed(this.errorMessage) : ok = false;
}

/// Manages Atlas staff. Creating a new staff member is done client-side using
/// a **secondary Firebase app instance** so the primary admin session is
/// preserved. This avoids any Cloud Function dependency.
///
/// Security is enforced in Firestore rules:
///   - Only users with isAtlas:true can write to users/{uid} with isAtlas field
///   - Only admin/owner can create new staff (checked in rules + UI gating)
class StaffManagementService {
  StaffManagementService._();
  static final instance = StaffManagementService._();

  final _db = FirebaseFirestore.instance;
  FirebaseApp? _secondaryApp;

  /// Streams every user with `isAtlas: true`.
  Stream<List<StaffUser>> watchAll() {
    return _db
        .collection('users')
        .where('isAtlas', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(StaffUser.fromFirestore).toList());
  }

  /// Lazily initialize the secondary Firebase app — this lets us create new
  /// user accounts without signing out the currently logged-in admin.
  Future<FirebaseApp> _getSecondaryApp() async {
    _secondaryApp ??= await Firebase.initializeApp(
      name: 'atlas_staff_creator',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return _secondaryApp!;
  }

  /// Creates a new Atlas staff account with email + password.
  /// The calling admin stays signed in.
  Future<StaffMutationResult> createStaffAccount({
    required String email,
    required String password,
    required String displayName,
    required StaffRole role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedName = displayName.trim();

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return const StaffMutationResult.failed('Valid email required.');
    }
    if (password.length < 8) {
      return const StaffMutationResult.failed('Password must be at least 8 characters.');
    }
    if (trimmedName.isEmpty) {
      return const StaffMutationResult.failed('Name required.');
    }

    FirebaseAuth? secondaryAuth;
    try {
      final secondaryApp = await _getSecondaryApp();
      secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Create the Firebase Auth user on the secondary instance — the
      // primary admin session is untouched.
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final uid = cred.user!.uid;
      await cred.user!.updateDisplayName(trimmedName);

      // Write the staff profile to Firestore (using the PRIMARY db — the
      // admin's credentials, which have permission).
      await _db.collection('users').doc(uid).set({
        'email': normalizedEmail,
        'displayName': trimmedName,
        'isAtlas': true,
        'staffRole': role.id,
        'mfaEnrolled': false,
        'disabled': false,
        'staffJoinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Sign the secondary instance out so the created account isn't left
      // signed-in on our secondary app.
      await secondaryAuth.signOut();

      AuditLogService.instance.log(
        action: 'ADDED_STAFF',
        targetType: 'staff',
        targetId: uid,
        targetDisplay: normalizedEmail,
        reason: 'Created ${role.label} account',
      );
      return const StaffMutationResult.success();
    } on FirebaseAuthException catch (e) {
      // Make sure the secondary instance is signed out on error
      await secondaryAuth?.signOut().catchError((_) {});
      return StaffMutationResult.failed(_friendlyAuthError(e));
    } catch (e) {
      await secondaryAuth?.signOut().catchError((_) {});
      return StaffMutationResult.failed(e.toString());
    }
  }

  Future<StaffMutationResult> changeRole(StaffUser staff, StaffRole newRole) async {
    if (staff.role == newRole) {
      return const StaffMutationResult.failed('Role is already that value.');
    }
    try {
      await _db.collection('users').doc(staff.uid).set({
        'staffRole': newRole.id,
      }, SetOptions(merge: true));

      AuditLogService.instance.log(
        action: 'CHANGED_STAFF_ROLE',
        targetType: 'staff',
        targetId: staff.uid,
        targetDisplay: staff.email,
        reason: 'Role: ${staff.role.label} → ${newRole.label}',
        changes: {
          'before': {'role': staff.role.id},
          'after': {'role': newRole.id},
        },
      );
      return const StaffMutationResult.success();
    } catch (e) {
      return StaffMutationResult.failed(e.toString());
    }
  }

  Future<StaffMutationResult> setDisabled(StaffUser staff, bool disabled) async {
    try {
      await _db.collection('users').doc(staff.uid).set({
        'disabled': disabled,
      }, SetOptions(merge: true));

      AuditLogService.instance.log(
        action: disabled ? 'REMOVED_STAFF' : 'ADDED_STAFF',
        targetType: 'staff',
        targetId: staff.uid,
        targetDisplay: staff.email,
        reason: disabled ? 'Atlas access revoked' : 'Atlas access restored',
      );
      return const StaffMutationResult.success();
    } catch (e) {
      return StaffMutationResult.failed(e.toString());
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'A user with that email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'invalid-email':
        return 'That email address is not valid.';
      default:
        return e.message ?? 'Failed to create account (${e.code}).';
    }
  }
}
