import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketStatus {
  newTicket('new', 'New'),
  open('open', 'Open'),
  pendingCustomer('pending_customer', 'Awaiting Customer'),
  resolved('resolved', 'Resolved'),
  closed('closed', 'Closed');

  final String id;
  final String label;
  const TicketStatus(this.id, this.label);

  static TicketStatus fromId(String? id) {
    return TicketStatus.values.firstWhere(
      (s) => s.id == id,
      orElse: () => TicketStatus.newTicket,
    );
  }

  bool get isClosed => this == resolved || this == closed;
}

enum TicketPriority {
  low('low', 'Low'),
  normal('normal', 'Normal'),
  high('high', 'High'),
  urgent('urgent', 'Urgent');

  final String id;
  final String label;
  const TicketPriority(this.id, this.label);

  static TicketPriority fromId(String? id) {
    return TicketPriority.values.firstWhere(
      (p) => p.id == id,
      orElse: () => TicketPriority.normal,
    );
  }
}

class SupportTicket {
  final String id;
  final String ticketNumber;
  final TicketStatus status;
  final TicketPriority priority;
  final String subject;
  final String description;
  final String orgId;
  final String orgName;
  final String? reportedByUid;
  final String? reportedByEmail;
  final String? assignedToUid;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final List<String> tags;
  final String sourceChannel;

  const SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.status,
    required this.priority,
    required this.subject,
    required this.description,
    required this.orgId,
    required this.orgName,
    this.reportedByUid,
    this.reportedByEmail,
    this.assignedToUid,
    this.assignedToName,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.tags = const [],
    this.sourceChannel = 'manual',
  });

  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SupportTicket(
      id: doc.id,
      ticketNumber: (data['ticketNumber'] ?? doc.id.substring(0, 6).toUpperCase()) as String,
      status: TicketStatus.fromId(data['status'] as String?),
      priority: TicketPriority.fromId(data['priority'] as String?),
      subject: (data['subject'] ?? 'Untitled') as String,
      description: (data['description'] ?? '') as String,
      orgId: (data['orgId'] ?? '') as String,
      orgName: (data['orgName'] ?? '') as String,
      reportedByUid: data['reportedByUid'] as String?,
      reportedByEmail: data['reportedByEmail'] as String?,
      assignedToUid: data['assignedToUid'] as String?,
      assignedToName: data['assignedToName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      tags: ((data['tags'] as List?) ?? []).map((e) => e.toString()).toList(),
      sourceChannel: (data['sourceChannel'] ?? 'manual') as String,
    );
  }
}

class TicketMessage {
  final String id;
  final DateTime timestamp;
  final String authorType; // "customer" | "staff"
  final String authorUid;
  final String authorName;
  final String body;
  final bool internalNote;

  const TicketMessage({
    required this.id,
    required this.timestamp,
    required this.authorType,
    required this.authorUid,
    required this.authorName,
    required this.body,
    this.internalNote = false,
  });

  factory TicketMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TicketMessage(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      authorType: (data['authorType'] ?? 'staff') as String,
      authorUid: (data['authorUid'] ?? '') as String,
      authorName: (data['authorName'] ?? 'Unknown') as String,
      body: (data['body'] ?? '') as String,
      internalNote: (data['internalNote'] ?? false) as bool,
    );
  }
}
