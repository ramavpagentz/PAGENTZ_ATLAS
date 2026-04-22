import 'dart:async';
import 'package:get/get.dart';
import '../../../core/models/staff_user_model.dart';
import '../../../core/services/staff_management_service.dart';

class StaffController extends GetxController {
  final all = <StaffUser>[].obs;
  final isLoading = true.obs;
  final query = ''.obs;
  final roleFilter = 'all'.obs;
  final showDisabled = false.obs;

  StreamSubscription<List<StaffUser>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = StaffManagementService.instance.watchAll().listen((list) {
      all.value = list;
      isLoading.value = false;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  List<StaffUser> get filtered {
    final q = query.value.trim().toLowerCase();
    final role = roleFilter.value;
    final showDis = showDisabled.value;

    final list = all.where((s) {
      if (!showDis && s.disabled) return false;
      if (role != 'all' && s.role.id != role) return false;
      if (q.isNotEmpty) {
        final hay = '${s.email} ${s.displayName}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      final r = b.role.level.compareTo(a.role.level);
      if (r != 0) return r;
      return a.email.compareTo(b.email);
    });
    return list;
  }
}
