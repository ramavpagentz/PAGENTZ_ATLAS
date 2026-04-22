import 'dart:async';
import 'package:get/get.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../core/services/ticket_service.dart';

class TicketController extends GetxController {
  final all = <SupportTicket>[].obs;
  final isLoading = true.obs;

  // Filters
  final query = ''.obs;
  final statusFilter = 'all'.obs;
  final priorityFilter = 'all'.obs;
  final myTicketsOnly = false.obs;

  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = TicketService.instance.watchAll().listen((list) {
      all.value = list;
      isLoading.value = false;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  List<SupportTicket> get filtered {
    final q = query.value.trim().toLowerCase();
    final status = statusFilter.value;
    final priority = priorityFilter.value;

    return all.where((t) {
      if (status != 'all' && t.status.id != status) return false;
      if (priority != 'all' && t.priority.id != priority) return false;
      if (q.isNotEmpty) {
        final hay =
            '${t.subject} ${t.orgName} ${t.ticketNumber} ${t.reportedByEmail ?? ''}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  int countByStatus(TicketStatus status) =>
      all.where((t) => t.status == status).length;
}
