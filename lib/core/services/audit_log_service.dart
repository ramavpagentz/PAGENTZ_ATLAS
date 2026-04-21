import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Writes immutable audit entries to `staff_audit_logs`.
///
/// Client-side writes are used for READ actions (VIEWED_*, VIEWED_PII). Any
/// WRITE action (impersonation, edits, reset password, disable customer) must
/// go through a Cloud Function wrapper that also writes the audit entry
/// atomically — do NOT add write-action logging here.
class AuditLogService {
  AuditLogService._();
  static final instance = AuditLogService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<void> log({
    required String action,
    required String targetType,
    required String targetId,
    String? targetDisplay,
    String? reason,
    Map<String, dynamic>? extra,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db.collection('staff_audit_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'staffUid': user.uid,
        'staffEmail': user.email,
        'staffTenantId': _auth.tenantId,
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'targetDisplay': targetDisplay,
        'reason': reason,
        'extra': extra,
      });
    } catch (_) {
      // Never throw from audit logging — a failed audit write must not block
      // the user's read action. Cloud Functions wrapper (Phase 4+) will harden
      // this for write actions.
    }
  }
}
