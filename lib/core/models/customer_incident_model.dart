import 'package:cloud_firestore/cloud_firestore.dart';

/// Read-only Atlas view of a customer-app incident (the customer-side
/// model lives in `inbound_emails` and is owned by the customer app).
/// We only model the fields the support view needs.
class CustomerIncident {
  final String id;
  final String orgId;
  final String teamId;
  final String teamName;
  final String incidentNumber;
  final String title;
  final String description;
  final String status; // open / ack / resolved
  final String severity;
  final String? priority; // P1..P4 (may be unset on older docs)
  final String? assignedName;
  final String? acknowledgedByName;
  final String? resolvedByName;
  final String? resolutionReason;
  final String from;
  final DateTime? createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final List<String> tags;

  CustomerIncident({
    required this.id,
    required this.orgId,
    required this.teamId,
    required this.teamName,
    required this.incidentNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.severity,
    required this.from,
    this.priority,
    this.assignedName,
    this.acknowledgedByName,
    this.resolvedByName,
    this.resolutionReason,
    this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.tags = const [],
  });

  factory CustomerIncident.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const <String, dynamic>{};
    DateTime? toDate(dynamic v) => v is Timestamp ? v.toDate() : null;
    final to = d['to'];
    return CustomerIncident(
      id: doc.id,
      orgId: (d['orgId'] as String?) ?? '',
      teamId: (d['teamId'] as String?) ?? '',
      teamName: (d['teamName'] as String?) ?? '',
      incidentNumber: (d['incidentNumber'] as String?) ?? '',
      title: (d['title'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      status: (d['status'] as String?) ?? 'open',
      severity: (d['severity'] as String?) ?? '',
      priority: d['priority'] as String?,
      assignedName: d['assignedName'] as String?,
      acknowledgedByName: d['acknowledgedByName'] as String?,
      resolvedByName: d['resolvedByName'] as String?,
      resolutionReason: d['resolutionReason'] as String?,
      from: (d['from'] as String?) ?? (to is String ? '' : ''),
      createdAt: toDate(d['createdAt']),
      acknowledgedAt: toDate(d['acknowledgedAt']),
      resolvedAt: toDate(d['resolvedAt']),
      tags: (d['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  /// Mean Time To Acknowledge in seconds. Null if not yet acked.
  int? get mttaSeconds {
    if (createdAt == null || acknowledgedAt == null) return null;
    return acknowledgedAt!.difference(createdAt!).inSeconds;
  }

  /// Mean Time To Resolve in seconds. Null if still open.
  int? get mttrSeconds {
    if (createdAt == null || resolvedAt == null) return null;
    return resolvedAt!.difference(createdAt!).inSeconds;
  }

  bool get isOpen => status == 'open';
  bool get isAcked => status == 'ack' || status == 'acknowledged';
  bool get isResolved => status == 'resolved';
}

class CustomerIncidentNote {
  final String id;
  final String body;
  final String authorName;
  final DateTime? createdAt;

  CustomerIncidentNote({
    required this.id,
    required this.body,
    required this.authorName,
    this.createdAt,
  });

  factory CustomerIncidentNote.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const <String, dynamic>{};
    final ts = d['createdAt'];
    return CustomerIncidentNote(
      id: doc.id,
      body: (d['body'] as String?) ?? '',
      authorName: (d['authorName'] as String?) ?? '—',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
