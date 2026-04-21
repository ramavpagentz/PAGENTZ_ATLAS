import 'package:get/get.dart';

import '../../../core/services/audit_log_service.dart';
import '../models/organization_model.dart';
import '../services/customer_service.dart';

class CustomerDetailController extends GetxController {
  final String orgId;
  CustomerDetailController(this.orgId);

  final _svc = CustomerService.instance;
  final _audit = AuditLogService.instance;

  final Rxn<Organization> org = Rxn<Organization>();
  final RxList<OrgMember> members = <OrgMember>[].obs;
  final RxBool loading = false.obs;
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
      final o = await _svc.getOrganization(orgId);
      if (o == null) {
        error.value = 'Organization not found';
        return;
      }
      org.value = o;
      members.value = await _svc.listMembers(orgId);
      _audit.log(
        action: 'VIEWED_CUSTOMER_DETAIL',
        targetType: 'org',
        targetId: orgId,
        targetDisplay: o.name,
      );
    } catch (e) {
      error.value = 'Failed to load: $e';
    } finally {
      loading.value = false;
    }
  }
}
