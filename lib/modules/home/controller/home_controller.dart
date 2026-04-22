import 'dart:async';
import 'package:get/get.dart';
import '../../../core/models/customer_org_model.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/ticket_service.dart';

class HomeController extends GetxController {
  final orgs = <CustomerOrg>[].obs;
  final tickets = <SupportTicket>[].obs;
  final isLoading = true.obs;

  StreamSubscription? _orgSub;
  StreamSubscription? _ticketSub;

  @override
  void onInit() {
    super.onInit();
    _orgSub = CustomerService.instance.watchOrganizations().listen((list) {
      orgs.value = list;
      _checkLoaded();
    });
    _ticketSub = TicketService.instance.watchAll().listen((list) {
      tickets.value = list;
      _checkLoaded();
    });
  }

  void _checkLoaded() {
    isLoading.value = false;
  }

  @override
  void onClose() {
    _orgSub?.cancel();
    _ticketSub?.cancel();
    super.onClose();
  }

  // ─── Customer KPIs ────────────────────────────────────────────────
  int get totalCustomers => orgs.length;

  int get activeThisMonth {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return orgs.where((o) => o.lastActiveAt != null && o.lastActiveAt!.isAfter(cutoff)).length;
  }

  int get newThisWeek {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return orgs.where((o) => o.createdAt != null && o.createdAt!.isAfter(cutoff)).length;
  }

  List<CustomerOrg> get recentSignups {
    final list = orgs.where((o) => o.createdAt != null).toList()
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    return list.take(5).toList();
  }

  // ─── Ticket KPIs ──────────────────────────────────────────────────
  int get openTicketCount => tickets
      .where((t) =>
          t.status != TicketStatus.resolved && t.status != TicketStatus.closed)
      .length;

  int get urgentTicketCount =>
      tickets.where((t) => t.priority == TicketPriority.urgent && !t.status.isClosed).length;

  List<SupportTicket> get urgentOpenTickets {
    final list = tickets
        .where((t) => !t.status.isClosed)
        .toList()
      ..sort((a, b) {
        final p = b.priority.index.compareTo(a.priority.index);
        if (p != 0) return p;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return list.take(5).toList();
  }

  // ─── System health ────────────────────────────────────────────────
  /// Best-effort health: if we have data flowing, services are reachable.
  bool get systemHealthy => !isLoading.value;
}
