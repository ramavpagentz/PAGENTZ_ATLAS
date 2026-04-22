import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../core/services/audit_log_service.dart';
import '../models/ticket_models.dart';
import '../services/ticket_service.dart';

class TicketDetailController extends GetxController {
  final String ticketId;
  TicketDetailController(this.ticketId);

  final _svc = TicketService.instance;
  final _audit = AuditLogService.instance;

  final Rxn<SupportTicket> ticket = Rxn<SupportTicket>();
  final RxList<TicketMessage> messages = <TicketMessage>[].obs;
  final RxBool loading = false.obs;
  final RxBool busy = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final t = await _svc.getTicket(ticketId);
      if (t == null) {
        error.value = 'Ticket not found';
        return;
      }
      ticket.value = t;
      messages.value = await _svc.listMessages(ticketId);
      _audit.log(
        action: 'VIEWED_TICKET',
        targetType: 'ticket',
        targetId: ticketId,
        targetDisplay: t.ticketNumber,
      );
    } catch (e) {
      error.value = 'Failed to load: $e';
    } finally {
      loading.value = false;
    }
  }

  Future<void> changeStatus(TicketStatus s) async {
    busy.value = true;
    try {
      await _svc.updateStatus(ticketId, s);
      await _audit.log(
        action: s == TicketStatus.resolved
            ? 'RESOLVED_TICKET'
            : 'CHANGED_TICKET_STATUS',
        targetType: 'ticket',
        targetId: ticketId,
        targetDisplay: ticket.value?.ticketNumber,
        extra: {'to': s.value},
      );
      await load();
    } finally {
      busy.value = false;
    }
  }

  Future<void> changePriority(TicketPriority p) async {
    busy.value = true;
    try {
      await _svc.updatePriority(ticketId, p);
      await _audit.log(
        action: 'CHANGED_TICKET_PRIORITY',
        targetType: 'ticket',
        targetId: ticketId,
        targetDisplay: ticket.value?.ticketNumber,
        extra: {'to': p.value},
      );
      await load();
    } finally {
      busy.value = false;
    }
  }

  Future<void> claim(String uid, String name) async {
    busy.value = true;
    try {
      await _svc.claimTicket(ticketId, uid, name);
      await _audit.log(
        action: 'CLAIMED_TICKET',
        targetType: 'ticket',
        targetId: ticketId,
        targetDisplay: ticket.value?.ticketNumber,
      );
      await load();
    } finally {
      busy.value = false;
    }
  }

  Future<void> unclaim() async {
    busy.value = true;
    try {
      await _svc.unclaimTicket(ticketId);
      await _audit.log(
        action: 'UNCLAIMED_TICKET',
        targetType: 'ticket',
        targetId: ticketId,
        targetDisplay: ticket.value?.ticketNumber,
      );
      await load();
    } finally {
      busy.value = false;
    }
  }

  Future<void> sendMessage({
    required String body,
    required bool internalNote,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    busy.value = true;
    try {
      await _svc.addMessage(
        ticketId: ticketId,
        body: body,
        internalNote: internalNote,
        authorUid: user.uid,
        authorName: user.displayName ?? user.email ?? user.uid,
      );
      await _audit.log(
        action: internalNote ? 'ADDED_INTERNAL_NOTE' : 'REPLIED_TO_TICKET',
        targetType: 'ticket',
        targetId: ticketId,
        targetDisplay: ticket.value?.ticketNumber,
      );
      await load();
    } finally {
      busy.value = false;
    }
  }
}
