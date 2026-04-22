import 'package:get/get.dart';

import '../../../core/services/audit_log_service.dart';
import '../models/ticket_models.dart';
import '../services/ticket_service.dart';

class TicketQueueController extends GetxController {
  final _svc = TicketService.instance;
  final _audit = AuditLogService.instance;

  final RxList<SupportTicket> tickets = <SupportTicket>[].obs;
  final Rx<TicketStatus?> statusFilter = Rx<TicketStatus?>(null);
  final RxnString assignedFilterUid = RxnString();
  final RxBool showOnlyMine = false.obs;
  final RxnString currentUid = RxnString();
  final RxString search = ''.obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  bool _auditedOnce = false;

  void setCurrentUid(String? uid) => currentUid.value = uid;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    loading.value = true;
    error.value = null;
    try {
      tickets.value = await _svc.listTickets(
        status: statusFilter.value,
        assignedToUid: showOnlyMine.value ? currentUid.value : null,
      );
      if (!_auditedOnce) {
        _audit.log(
          action: 'VIEWED_TICKET_QUEUE',
          targetType: 'system',
          targetId: 'support_tickets',
        );
        _auditedOnce = true;
      }
    } catch (e) {
      error.value = 'Failed to load tickets: $e';
    } finally {
      loading.value = false;
    }
  }

  List<SupportTicket> get filtered {
    final q = search.value.trim().toLowerCase();
    if (q.isEmpty) return tickets;
    return tickets.where((t) {
      return t.subject.toLowerCase().contains(q) ||
          t.ticketNumber.toLowerCase().contains(q) ||
          (t.orgName?.toLowerCase().contains(q) ?? false) ||
          (t.reportedByEmail?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void setStatusFilter(TicketStatus? s) {
    statusFilter.value = s;
    reload();
  }

  void toggleMineOnly(bool v) {
    showOnlyMine.value = v;
    reload();
  }
}
