import 'package:cloud_firestore/cloud_firestore.dart';

enum ImpersonationMode {
  readOnly('read_only', 'Read-only'),
  readWrite('read_write', 'Read-write');

  final String id;
  final String label;
  const ImpersonationMode(this.id, this.label);

  static ImpersonationMode fromId(String? id) =>
      id == 'read_write' ? readWrite : readOnly;
}

class ImpersonationSession {
  final String id;
  final String staffUid;
  final String staffEmail;
  final String targetOrgId;
  final String targetUid;
  final String? targetEmail;
  final String reason;
  final ImpersonationMode mode;
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime? endedAt;

  const ImpersonationSession({
    required this.id,
    required this.staffUid,
    required this.staffEmail,
    required this.targetOrgId,
    required this.targetUid,
    this.targetEmail,
    required this.reason,
    required this.mode,
    required this.startedAt,
    required this.expiresAt,
    this.endedAt,
  });

  bool get isActive =>
      endedAt == null && DateTime.now().isBefore(expiresAt);

  factory ImpersonationSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ImpersonationSession(
      id: doc.id,
      staffUid: (data['staffUid'] ?? '') as String,
      staffEmail: (data['staffEmail'] ?? '') as String,
      targetOrgId: (data['targetOrgId'] ?? '') as String,
      targetUid: (data['targetUid'] ?? '') as String,
      targetEmail: data['targetEmail'] as String?,
      reason: (data['reason'] ?? '') as String,
      mode: ImpersonationMode.fromId(data['mode'] as String?),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 1)),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
    );
  }
}
