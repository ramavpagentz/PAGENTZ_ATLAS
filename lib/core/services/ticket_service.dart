import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/staff_user_model.dart';
import '../models/support_ticket_model.dart';
import 'audit_log_service.dart';

class TicketService {
  TicketService._();
  static final instance = TicketService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// All tickets, most recent first.
  Stream<List<SupportTicket>> watchAll({int limit = 200}) {
    return _db
        .collection('support_tickets')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(SupportTicket.fromFirestore).toList());
  }

  /// Tickets for a specific organization.
  Stream<List<SupportTicket>> watchForOrg(String orgId) {
    return _db
        .collection('support_tickets')
        .where('orgId', isEqualTo: orgId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(SupportTicket.fromFirestore).toList());
  }

  Stream<SupportTicket?> watchOne(String ticketId) {
    return _db.collection('support_tickets').doc(ticketId).snapshots().map(
      (d) => d.exists ? SupportTicket.fromFirestore(d) : null,
    );
  }

  Stream<List<TicketMessage>> watchMessages(String ticketId) {
    return _db
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((s) => s.docs.map(TicketMessage.fromFirestore).toList());
  }

  /// Generate a short ticket number like "T-A4F2C".
  String _generateTicketNumber() {
    final now = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    return 'T-${now.substring(now.length - 5)}';
  }

  Future<String> createTicket({
    required String orgId,
    required String orgName,
    required String subject,
    required String description,
    TicketPriority priority = TicketPriority.normal,
    String? reportedByEmail,
    String? reportedByUid,
    StaffUser? actingStaff,
  }) async {
    final ticketNumber = _generateTicketNumber();
    final ref = await _db.collection('support_tickets').add({
      'ticketNumber': ticketNumber,
      'status': TicketStatus.newTicket.id,
      'priority': priority.id,
      'subject': subject.trim(),
      'description': description.trim(),
      'orgId': orgId,
      'orgName': orgName,
      'reportedByUid': reportedByUid,
      'reportedByEmail': reportedByEmail,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'sourceChannel': 'manual',
      'tags': <String>[],
    });

    AuditLogService.instance.log(
      action: 'CREATED_TICKET',
      targetType: 'ticket',
      targetId: ref.id,
      targetDisplay: '$ticketNumber · $subject',
      reason: 'For org $orgName',
    );
    return ref.id;
  }

  Future<void> assignTo(String ticketId, StaffUser staff) async {
    await _db.collection('support_tickets').doc(ticketId).update({
      'assignedToUid': staff.uid,
      'assignedToName': staff.displayName.isNotEmpty ? staff.displayName : staff.email,
      'updatedAt': FieldValue.serverTimestamp(),
      if ((await _db.collection('support_tickets').doc(ticketId).get()).data()?['status'] ==
              TicketStatus.newTicket.id)
        'status': TicketStatus.open.id,
    });
  }

  Future<void> updateStatus(String ticketId, TicketStatus status) async {
    final updates = <String, dynamic>{
      'status': status.id,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == TicketStatus.resolved) {
      updates['resolvedAt'] = FieldValue.serverTimestamp();
    }
    await _db.collection('support_tickets').doc(ticketId).update(updates);

    if (status == TicketStatus.resolved) {
      AuditLogService.instance.log(
        action: 'RESOLVED_TICKET',
        targetType: 'ticket',
        targetId: ticketId,
      );
    }
  }

  Future<void> updatePriority(String ticketId, TicketPriority priority) async {
    await _db.collection('support_tickets').doc(ticketId).update({
      'priority': priority.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addMessage({
    required String ticketId,
    required String body,
    required bool internalNote,
    required StaffUser staff,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .add({
      'timestamp': FieldValue.serverTimestamp(),
      'authorType': 'staff',
      'authorUid': user.uid,
      'authorName': staff.displayName.isNotEmpty ? staff.displayName : staff.email,
      'body': body.trim(),
      'internalNote': internalNote,
    });
    await _db.collection('support_tickets').doc(ticketId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
