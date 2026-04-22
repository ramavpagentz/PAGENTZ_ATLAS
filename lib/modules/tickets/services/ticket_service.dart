import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/ticket_models.dart';

class TicketService {
  TicketService._();
  static final instance = TicketService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<List<SupportTicket>> listTickets({
    TicketStatus? status,
    String? assignedToUid,
    String? orgId,
    int limit = 100,
  }) async {
    Query<Map<String, dynamic>> q = _db.collection('support_tickets');
    if (status != null) {
      q = q.where('status', isEqualTo: status.value);
    }
    if (assignedToUid != null && assignedToUid.isNotEmpty) {
      q = q.where('assignedToUid', isEqualTo: assignedToUid);
    }
    if (orgId != null && orgId.isNotEmpty) {
      q = q.where('orgId', isEqualTo: orgId);
    }
    q = q.orderBy('createdAt', descending: true).limit(limit);
    final snap = await q.get();
    return snap.docs.map((d) => SupportTicket.fromFirestore(d)).toList();
  }

  Future<SupportTicket?> getTicket(String ticketId) async {
    final doc = await _db.collection('support_tickets').doc(ticketId).get();
    if (!doc.exists) return null;
    return SupportTicket.fromFirestore(doc);
  }

  Future<List<TicketMessage>> listMessages(String ticketId) async {
    final snap = await _db
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .get();
    return snap.docs.map((d) => TicketMessage.fromFirestore(d)).toList();
  }

  String _generateTicketNumber() {
    // Human-readable, reasonably unique. Format: T-XXXXXX from ms timestamp
    final ms = DateTime.now().millisecondsSinceEpoch;
    final n = (ms % 1000000).toString().padLeft(6, '0');
    return 'T-$n';
  }

  Future<SupportTicket> createTicket({
    required String subject,
    required String description,
    required TicketPriority priority,
    String? orgId,
    String? orgName,
    String? reportedByUid,
    String? reportedByEmail,
    List<String> tags = const [],
  }) async {
    final user = _auth.currentUser;
    final ref = _db.collection('support_tickets').doc();
    final ticketNumber = _generateTicketNumber();
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'ticketNumber': ticketNumber,
      'status': TicketStatus.newT.value,
      'priority': priority.value,
      'subject': subject,
      'description': description,
      'orgId': orgId,
      'orgName': orgName,
      'reportedByUid': reportedByUid,
      'reportedByEmail': reportedByEmail,
      'assignedToUid': null,
      'assignedToName': null,
      'createdAt': now,
      'updatedAt': now,
      'tags': tags,
      'sourceChannel': 'manual',
      'createdByStaffUid': user?.uid,
    };
    await ref.set(data);
    final snap = await ref.get();
    return SupportTicket.fromFirestore(snap);
  }

  Future<void> updateStatus(String ticketId, TicketStatus status) async {
    final patch = <String, dynamic>{
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == TicketStatus.resolved || status == TicketStatus.closed) {
      patch['resolvedAt'] = FieldValue.serverTimestamp();
    }
    await _db.collection('support_tickets').doc(ticketId).update(patch);
  }

  Future<void> updatePriority(
      String ticketId, TicketPriority priority) async {
    await _db.collection('support_tickets').doc(ticketId).update({
      'priority': priority.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> claimTicket(
      String ticketId, String uid, String name) async {
    await _db.collection('support_tickets').doc(ticketId).update({
      'assignedToUid': uid,
      'assignedToName': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unclaimTicket(String ticketId) async {
    await _db.collection('support_tickets').doc(ticketId).update({
      'assignedToUid': null,
      'assignedToName': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addMessage({
    required String ticketId,
    required String body,
    required bool internalNote,
    required String authorUid,
    required String authorName,
  }) async {
    final ref = _db
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .doc();
    await ref.set({
      'timestamp': FieldValue.serverTimestamp(),
      'authorType': 'staff',
      'authorUid': authorUid,
      'authorName': authorName,
      'body': body,
      'internalNote': internalNote,
    });
    final ticketRef = _db.collection('support_tickets').doc(ticketId);
    await ticketRef.update({
      'updatedAt': FieldValue.serverTimestamp(),
      'firstResponseAt': FieldValue.serverTimestamp(),
    }).catchError((_) {
      // firstResponseAt may already be set; fall back to just bumping updatedAt.
      return ticketRef.update({'updatedAt': FieldValue.serverTimestamp()});
    });
  }
}
