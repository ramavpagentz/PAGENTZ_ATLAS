import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketStatus { newT, open, pendingCustomer, resolved, closed }

extension TicketStatusX on TicketStatus {
  String get value {
    switch (this) {
      case TicketStatus.newT:
        return 'new';
      case TicketStatus.open:
        return 'open';
      case TicketStatus.pendingCustomer:
        return 'pending_customer';
      case TicketStatus.resolved:
        return 'resolved';
      case TicketStatus.closed:
        return 'closed';
    }
  }

  String get label {
    switch (this) {
      case TicketStatus.newT:
        return 'New';
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.pendingCustomer:
        return 'Pending customer';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  bool get isActive =>
      this == TicketStatus.newT ||
      this == TicketStatus.open ||
      this == TicketStatus.pendingCustomer;

  static TicketStatus? fromString(String? s) {
    if (s == null) return null;
    for (final v in TicketStatus.values) {
      if (v.value == s) return v;
    }
    return null;
  }
}

enum TicketPriority { low, normal, high, urgent }

extension TicketPriorityX on TicketPriority {
  String get value {
    switch (this) {
      case TicketPriority.low:
        return 'low';
      case TicketPriority.normal:
        return 'normal';
      case TicketPriority.high:
        return 'high';
      case TicketPriority.urgent:
        return 'urgent';
    }
  }

  String get label =>
      value[0].toUpperCase() + value.substring(1).replaceAll('_', ' ');

  static TicketPriority? fromString(String? s) {
    if (s == null) return null;
    for (final v in TicketPriority.values) {
      if (v.value == s) return v;
    }
    return null;
  }
}

class SupportTicket {
  final String id;
  final String ticketNumber;
  final TicketStatus status;
  final TicketPriority priority;
  final String subject;
  final String description;
  final String? orgId;
  final String? orgName;
  final String? reportedByUid;
  final String? reportedByEmail;
  final String? assignedToUid;
  final String? assignedToName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? firstResponseAt;
  final DateTime? resolvedAt;
  final List<String> tags;
  final String? sourceChannel;
  final String? createdByStaffUid;

  SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.status,
    required this.priority,
    required this.subject,
    required this.description,
    this.orgId,
    this.orgName,
    this.reportedByUid,
    this.reportedByEmail,
    this.assignedToUid,
    this.assignedToName,
    this.createdAt,
    this.updatedAt,
    this.firstResponseAt,
    this.resolvedAt,
    this.tags = const [],
    this.sourceChannel,
    this.createdByStaffUid,
  });

  factory SupportTicket.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return SupportTicket(
      id: doc.id,
      ticketNumber: (d['ticketNumber'] ?? doc.id) as String,
      status: TicketStatusX.fromString(d['status'] as String?) ??
          TicketStatus.newT,
      priority: TicketPriorityX.fromString(d['priority'] as String?) ??
          TicketPriority.normal,
      subject: (d['subject'] ?? '') as String,
      description: (d['description'] ?? '') as String,
      orgId: d['orgId'] as String?,
      orgName: d['orgName'] as String?,
      reportedByUid: d['reportedByUid'] as String?,
      reportedByEmail: d['reportedByEmail'] as String?,
      assignedToUid: d['assignedToUid'] as String?,
      assignedToName: d['assignedToName'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      firstResponseAt: (d['firstResponseAt'] as Timestamp?)?.toDate(),
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
      tags: (d['tags'] as List?)?.cast<String>() ?? const [],
      sourceChannel: d['sourceChannel'] as String?,
      createdByStaffUid: d['createdByStaffUid'] as String?,
    );
  }
}

class TicketMessage {
  final String id;
  final DateTime? timestamp;
  final String authorType; // 'customer' | 'staff'
  final String? authorUid;
  final String? authorName;
  final String body;
  final bool internalNote;

  TicketMessage({
    required this.id,
    this.timestamp,
    required this.authorType,
    this.authorUid,
    this.authorName,
    required this.body,
    required this.internalNote,
  });

  factory TicketMessage.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return TicketMessage(
      id: doc.id,
      timestamp: (d['timestamp'] as Timestamp?)?.toDate(),
      authorType: (d['authorType'] ?? 'staff') as String,
      authorUid: d['authorUid'] as String?,
      authorName: d['authorName'] as String?,
      body: (d['body'] ?? '') as String,
      internalNote: (d['internalNote'] ?? false) as bool,
    );
  }
}
