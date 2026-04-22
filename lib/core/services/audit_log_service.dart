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

  Future<void> log({
    required String action,
    required String targetType,
    required String targetId,
    String? targetDisplay,
    String? reason,
    Map<String, dynamic>? changes,
  }) async {
    final user = _auth.currentUser;
    final staff = _currentStaff;
    if (user == null || staff == null) return;

    try {
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
    } catch (_) {
      // Audit log failure should never break the user-facing action.
      // In production, route this to a separate error reporter.
    }
  }
}
