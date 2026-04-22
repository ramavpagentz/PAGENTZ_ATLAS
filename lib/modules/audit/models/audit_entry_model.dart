import 'package:cloud_firestore/cloud_firestore.dart';

class AuditEntry {
  final String id;
  final DateTime? timestamp;
  final String? staffUid;
  final String? staffEmail;
  final String? staffRole;
  final String? staffTenantId;
  final String action;
  final String? targetType;
  final String? targetId;
  final String? targetDisplay;
  final String? reason;
  final String? ipAddress;
  final Map<String, dynamic>? extra;
  final Map<String, dynamic>? changes;

  AuditEntry({
    required this.id,
    this.timestamp,
    this.staffUid,
    this.staffEmail,
    this.staffRole,
    this.staffTenantId,
    required this.action,
    this.targetType,
    this.targetId,
    this.targetDisplay,
    this.reason,
    this.ipAddress,
    this.extra,
    this.changes,
  });

  factory AuditEntry.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return AuditEntry(
      id: doc.id,
      timestamp: (d['timestamp'] as Timestamp?)?.toDate(),
      staffUid: d['staffUid'] as String?,
      staffEmail: d['staffEmail'] as String?,
      staffRole: d['staffRole'] as String?,
      staffTenantId: d['staffTenantId'] as String?,
      action: (d['action'] ?? 'UNKNOWN') as String,
      targetType: d['targetType'] as String?,
      targetId: d['targetId'] as String?,
      targetDisplay: d['targetDisplay'] as String?,
      reason: d['reason'] as String?,
      ipAddress: d['ipAddress'] as String?,
      extra: d['extra'] as Map<String, dynamic>?,
      changes: d['changes'] as Map<String, dynamic>?,
    );
  }

  /// One-line CSV-friendly representation. Newlines stripped from values.
  List<String> toCsvRow() {
    String s(String? v) => (v ?? '').replaceAll('\n', ' ').replaceAll('\r', ' ');
    return [
      timestamp?.toUtc().toIso8601String() ?? '',
      s(staffEmail),
      s(staffUid),
      action,
      s(targetType),
      s(targetId),
      s(targetDisplay),
      s(reason),
      s(ipAddress),
    ];
  }

  static const List<String> csvHeader = [
    'timestamp_utc',
    'staff_email',
    'staff_uid',
    'action',
    'target_type',
    'target_id',
    'target_display',
    'reason',
    'ip_address',
  ];
}
