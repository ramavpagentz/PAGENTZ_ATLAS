import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../core/services/audit_log_service.dart';
import '../models/audit_entry_model.dart';
import '../services/audit_query_service.dart';

class AuditLogController extends GetxController {
  final _svc = AuditQueryService.instance;
  final _audit = AuditLogService.instance;

  final RxList<AuditEntry> entries = <AuditEntry>[].obs;
  final RxList<String> knownActions = <String>[].obs;

  final Rx<AuditQueryFilter> filter =
      const AuditQueryFilter().obs;

  final RxBool loadingFirstPage = false.obs;
  final RxBool loadingMore = false.obs;
  final RxBool exhausted = false.obs;
  final RxnString error = RxnString();

  DocumentSnapshot? _cursor;

  static const int _pageSize = 50;

  bool _auditedOnce = false;

  @override
  void onInit() {
    super.onInit();
    _svc.distinctRecentActions().then((a) => knownActions.value = a);
    reload();
  }

  Future<void> reload() async {
    loadingFirstPage.value = true;
    loadingMore.value = false;
    exhausted.value = false;
    error.value = null;
    _cursor = null;
    entries.clear();
    try {
      final page =
          await _svc.fetchPage(filter: filter.value, limit: _pageSize);
      entries.assignAll(page.entries);
      _cursor = page.cursor;
      if (page.entries.length < _pageSize) exhausted.value = true;
      if (!_auditedOnce) {
        _audit.log(
          action: 'VIEWED_AUDIT_LOG',
          targetType: 'system',
          targetId: 'staff_audit_logs',
        );
        _auditedOnce = true;
      }
    } catch (e) {
      error.value = 'Failed to load audit log: $e';
    } finally {
      loadingFirstPage.value = false;
    }
  }

  Future<void> loadMore() async {
    if (loadingMore.value || exhausted.value || _cursor == null) return;
    loadingMore.value = true;
    error.value = null;
    try {
      final page = await _svc.fetchPage(
        filter: filter.value,
        limit: _pageSize,
        startAfter: _cursor,
      );
      entries.addAll(page.entries);
      _cursor = page.cursor;
      if (page.entries.length < _pageSize) exhausted.value = true;
    } catch (e) {
      error.value = 'Failed to load more: $e';
    } finally {
      loadingMore.value = false;
    }
  }

  void setActionFilter(String? action) {
    filter.value = filter.value.copyWith(
      action: action,
      clearAction: action == null,
    );
    reload();
  }

  void setStaffFilter(String? uid) {
    filter.value = filter.value.copyWith(
      staffUid: uid,
      clearStaffUid: uid == null,
    );
    reload();
  }

  void setTargetFilter(String? targetId) {
    filter.value = filter.value.copyWith(
      targetId: targetId,
      clearTargetId: targetId == null,
    );
    reload();
  }

  void clearFilters() {
    filter.value = const AuditQueryFilter();
    reload();
  }
}
