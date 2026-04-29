import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/staff_user_model.dart';

/// Writes audit log entries to `staff_audit_logs`. Append-only, enforced by
/// Firestore security rules.
///
/// In production, sensitive write actions should go through Cloud Functions
/// that wrap the action + audit log in a transaction. For UI-only events
/// (viewing a customer, viewing PII), direct client writes are acceptable.
class AuditLogService {
  AuditLogService._();
  static final instance = AuditLogService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  StaffUser? _currentStaff;

  void setCurrentStaff(StaffUser staff) {
    _currentStaff = staff;
  }

  /// Best-effort audit log write. Swallows errors so the user-facing
  /// action isn't broken by an audit blip.
  ///
  /// **Do not use this for security-critical reveals or destructive
  /// admin actions** — those must use [logStrict] so a failed audit
  /// fails the action closed.
  Future<void> log({
    required String action,
    required String targetType,
    required String targetId,
    String? targetDisplay,
    String? reason,
    Map<String, dynamic>? changes,
  }) async {
    try {
      await _write(
        action: action,
        targetType: targetType,
        targetId: targetId,
        targetDisplay: targetDisplay,
        reason: reason,
        changes: changes,
      );
    } catch (_) {
      // Best-effort. In production, route this to a separate error reporter.
    }
  }

  /// Strict audit log write. Throws if the audit row cannot be persisted —
  /// callers should catch and refuse the user-facing action when that
  /// happens. Use for reveal-with-reason flows, password resets, force
  /// sign-out, and any other "if it didn't audit, it must not happen"
  /// operation.
  Future<void> logStrict({
    required String action,
    required String targetType,
    required String targetId,
    String? targetDisplay,
    String? reason,
    Map<String, dynamic>? changes,
  }) async {
    await _write(
      action: action,
      targetType: targetType,
      targetId: targetId,
      targetDisplay: targetDisplay,
      reason: reason,
      changes: changes,
    );
  }

  Future<void> _write({
    required String action,
    required String targetType,
    required String targetId,
    String? targetDisplay,
    String? reason,
    Map<String, dynamic>? changes,
  }) async {
    final user = _auth.currentUser;
    final staff = _currentStaff;
    if (user == null) {
      throw StateError('Audit log: no authenticated user.');
    }
    if (staff == null) {
      throw StateError('Audit log: staff context not loaded.');
    }
    await _db.collection('staff_audit_logs').add({
      'timestamp': FieldValue.serverTimestamp(),
      'staffUid': user.uid,
      'staffEmail': staff.email,
      'staffRole': staff.role.id,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      if (targetDisplay != null) 'targetDisplay': targetDisplay,
      if (reason != null) 'reason': reason,
      if (changes != null) 'changes': changes,
    });
  }
}
