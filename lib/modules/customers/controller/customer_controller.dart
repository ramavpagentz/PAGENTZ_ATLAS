import 'dart:async';
import 'package:get/get.dart';
import '../../../core/models/customer_org_model.dart';
import '../../../core/services/audit_log_service.dart';
import '../../../core/services/customer_service.dart';

class CustomerController extends GetxController {
  final all = <CustomerOrg>[].obs;
  final isLoading = true.obs;
  final query = ''.obs;
  final planFilter = 'all'.obs;
  final statusFilter = 'all'.obs;

  final selected = Rxn<CustomerOrg>();
  final selectedLoading = false.obs;

  StreamSubscription<List<CustomerOrg>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = CustomerService.instance.watchOrganizations().listen((list) {
      all.value = list;
      isLoading.value = false;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  List<CustomerOrg> get filtered {
    final q = query.value.trim().toLowerCase();
    final plan = planFilter.value;
    final status = statusFilter.value;

    return all.where((o) {
      if (q.isNotEmpty) {
        final hay = '${o.name} ${o.email ?? ''} ${o.website ?? ''} ${o.industry ?? ''}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (plan != 'all' && (o.plan ?? 'free') != plan) return false;
      if (status != 'all' && (o.planStatus ?? 'active') != status) return false;
      return true;
    }).toList();
  }

  Future<void> openCustomer(String orgId) async {
    selectedLoading.value = true;
    selected.value = null;
    final org = await CustomerService.instance.getOrganization(orgId);
    selected.value = org;
    selectedLoading.value = false;

    if (org != null) {
      AuditLogService.instance.log(
        action: 'VIEWED_CUSTOMER',
        targetType: 'org',
        targetId: org.id,
        targetDisplay: org.name,
      );
    }
  }

  void clearSelected() {
    selected.value = null;
  }
}
