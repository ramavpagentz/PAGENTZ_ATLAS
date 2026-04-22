import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/audit_log_model.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../core/services/audit_log_service.dart';
import '../../../utils/csv_download.dart';

class AuditLogController extends GetxController {
  final all = <AuditLog>[].obs;
  final isLoading = true.obs;

  // Filters
  final query = ''.obs;
  final actionFilter = 'all'.obs;
  final staffFilter = 'all'.obs;

  StreamSubscription<List<AuditLog>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = ActivityLogService.instance.watchStaffAudit().listen((list) {
      all.value = list;
      isLoading.value = false;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  /// Distinct actions present in the data, for the action filter dropdown.
  List<String> get availableActions {
    final s = <String>{};
    for (final l in all) {
      if (l.action.isNotEmpty) s.add(l.action);
    }
    final sorted = s.toList()..sort();
    return sorted;
  }

  /// Distinct staff emails for the staff filter dropdown.
  List<String> get availableStaff {
    final s = <String>{};
    for (final l in all) {
      if (l.staffEmail.isNotEmpty) s.add(l.staffEmail);
    }
    final sorted = s.toList()..sort();
    return sorted;
  }

  List<AuditLog> get filtered {
    final q = query.value.trim().toLowerCase();
    final action = actionFilter.value;
    final staff = staffFilter.value;

    return all.where((l) {
      if (action != 'all' && l.action != action) return false;
      if (staff != 'all' && l.staffEmail != staff) return false;
      if (q.isNotEmpty) {
        final hay =
            '${l.staffEmail} ${l.action} ${l.targetDisplay ?? ''} ${l.targetId} ${l.reason ?? ''}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  void exportCsv() {
    final df = DateFormat('yyyy-MM-dd HH:mm:ss');
    final rows = <List<dynamic>>[
      ['Timestamp', 'Staff', 'Role', 'Action', 'Target Type', 'Target', 'Reason', 'IP'],
      ...filtered.map((l) => [
            df.format(l.timestamp),
            l.staffEmail,
            l.staffRole,
            l.action,
            l.targetType,
            l.targetDisplay ?? l.targetId,
            l.reason ?? '',
            l.ipAddress ?? '',
          ]),
    ];
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    downloadCsv(filename: 'atlas_audit_log_$stamp.csv', rows: rows);

    AuditLogService.instance.log(
      action: 'EXPORTED_DATA',
      targetType: 'audit_log',
      targetId: 'staff_audit_logs',
      reason: 'CSV export of ${filtered.length} audit entries',
    );
  }
}
