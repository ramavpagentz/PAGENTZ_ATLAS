import 'package:get/get.dart';

import '../../../core/services/audit_log_service.dart';
import '../models/organization_model.dart';
import '../services/customer_service.dart';

class CustomerDirectoryController extends GetxController {
  final _svc = CustomerService.instance;
  final _audit = AuditLogService.instance;

  final RxList<Organization> orgs = <Organization>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  bool _auditedThisSession = false;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    loading.value = true;
    error.value = null;
    try {
      orgs.value = await _svc.listOrganizations();
      if (!_auditedThisSession) {
        _audit.log(
          action: 'VIEWED_CUSTOMER_DIRECTORY',
          targetType: 'system',
          targetId: 'directory',
        );
        _auditedThisSession = true;
      }
    } catch (e) {
      error.value = 'Failed to load: $e';
    } finally {
      loading.value = false;
    }
  }

  List<Organization> get filtered {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return orgs;
    return orgs.where((o) {
      return o.name.toLowerCase().contains(q) ||
          (o.email?.toLowerCase().contains(q) ?? false) ||
          (o.website?.toLowerCase().contains(q) ?? false) ||
          (o.industry?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}
