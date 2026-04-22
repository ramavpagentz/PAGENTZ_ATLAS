import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_log_model.dart';
import '../models/audit_log_model.dart';

/// Reads activity_logs (customer-side) and staff_audit_logs (staff-side).
class ActivityLogService {
  ActivityLogService._();
  static final instance = ActivityLogService._();

  final _db = FirebaseFirestore.instance;

  /// Customer activity for a specific org.
  Stream<List<ActivityLog>> watchOrgActivity(String orgId, {int limit = 200}) {
    return _db
        .collection('activity_logs')
        .where('orgId', isEqualTo: orgId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ActivityLog.fromFirestore).toList());
  }

  /// All staff audit log entries (admin/owner only — Firestore rules enforce).
  Stream<List<AuditLog>> watchStaffAudit({int limit = 500}) {
    return _db
        .collection('staff_audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AuditLog.fromFirestore).toList());
  }
}
