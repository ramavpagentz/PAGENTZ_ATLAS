import 'package:cloud_firestore/cloud_firestore.dart';

/// Customer-side activity log entry — read from the existing `activity_logs`
/// collection that the customer app writes (login events, config changes,
/// incidents, etc.).
///
/// Distinct from `AuditLog` which is staff-side.
class ActivityLog {
  final String id;
  final DateTime timestamp;
  final String module;        // "auth" | "incidents" | "schedules" | ...
  final String category;      // "security" | "config" | "operations" | ...
  final String eventType;     // "LOGIN_SUCCESS" | "ESCALATION_UPDATED" | ...
  final String eventLabel;
  final String actorId;
  final String actorDisplay;
  final String? actorType;    // "user" | "staff_impersonating"
  final String targetType;
  final String targetId;
  final String? targetDisplay;
  final String? orgId;

  const ActivityLog({
    required this.id,
    required this.timestamp,
    required this.module,
    required this.category,
    required this.eventType,
    required this.eventLabel,
    required this.actorId,
    required this.actorDisplay,
    this.actorType,
    required this.targetType,
    required this.targetId,
    this.targetDisplay,
    this.orgId,
  });

  factory ActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ActivityLog(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      module: (data['module'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      eventType: (data['eventType'] ?? '') as String,
      eventLabel: (data['eventLabel'] ?? data['eventType'] ?? 'Event') as String,
      actorId: (data['actorId'] ?? '') as String,
      actorDisplay: (data['actorDisplay'] ?? data['actorId'] ?? 'Unknown') as String,
      actorType: data['actorType'] as String?,
      targetType: (data['targetType'] ?? '') as String,
      targetId: (data['targetId'] ?? '') as String,
      targetDisplay: data['targetDisplay'] as String?,
      orgId: data['orgId'] as String?,
    );
  }
}
