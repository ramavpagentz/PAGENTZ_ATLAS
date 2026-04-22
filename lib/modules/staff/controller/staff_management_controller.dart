import 'package:get/get.dart';

import '../../../core/services/audit_log_service.dart';
import '../models/staff_listing_model.dart';
import '../services/staff_management_service.dart';

class StaffManagementController extends GetxController {
  final _svc = StaffManagementService.instance;
  final _audit = AuditLogService.instance;

  final RxList<StaffListing> staff = <StaffListing>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();
  final RxBool busy = false.obs;

  bool _auditedOnce = false;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    loading.value = true;
    error.value = null;
    try {
      staff.value = await _svc.listStaff();
      if (!_auditedOnce) {
        _audit.log(
          action: 'VIEWED_STAFF_LIST',
          targetType: 'system',
          targetId: 'staff',
        );
        _auditedOnce = true;
      }
    } catch (e) {
      error.value = 'Failed to load staff: $e';
    } finally {
      loading.value = false;
    }
  }

  Future<CreateStaffResult> addStaff({
    required String email,
    required String displayName,
    required String role,
    String? reason,
  }) async {
    busy.value = true;
    try {
      final res = await _svc.createStaff(
        email: email,
        displayName: displayName,
        role: role,
        reason: reason,
      );
      // Refresh in background
      reload();
      return res;
    } finally {
      busy.value = false;
    }
  }

  Future<bool> changeRole({
    required String uid,
    required String newRole,
    String? reason,
  }) async {
    busy.value = true;
    try {
      final changed = await _svc.updateStaffRole(
        uid: uid,
        newRole: newRole,
        reason: reason,
      );
      if (changed) reload();
      return changed;
    } finally {
      busy.value = false;
    }
  }

  Future<void> setDisabled({
    required String uid,
    required bool disabled,
    String? reason,
  }) async {
    busy.value = true;
    try {
      await _svc.setStaffDisabled(
        uid: uid,
        disabled: disabled,
        reason: reason,
      );
      reload();
    } finally {
      busy.value = false;
    }
  }

  Future<ResetPasswordResult> resetPassword({
    required String uid,
    String? reason,
  }) async {
    busy.value = true;
    try {
      return await _svc.resetStaffPassword(uid: uid, reason: reason);
    } finally {
      busy.value = false;
    }
  }
}
