import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/audit_entry_model.dart';

class AuditQueryFilter {
  final String? staffUid;
  final String? action;
  final String? targetId;
  final DateTime? from;
  final DateTime? to;

  const AuditQueryFilter({
    this.staffUid,
    this.action,
    this.targetId,
    this.from,
    this.to,
  });

  bool get isEmpty =>
      staffUid == null &&
      action == null &&
      targetId == null &&
      from == null &&
      to == null;

  AuditQueryFilter copyWith({
    String? staffUid,
    String? action,
    String? targetId,
    DateTime? from,
    DateTime? to,
    bool clearStaffUid = false,
    bool clearAction = false,
    bool clearTargetId = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return AuditQueryFilter(
      staffUid: clearStaffUid ? null : (staffUid ?? this.staffUid),
      action: clearAction ? null : (action ?? this.action),
      targetId: clearTargetId ? null : (targetId ?? this.targetId),
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
    );
  }
}

class AuditQueryService {
  AuditQueryService._();
  static final instance = AuditQueryService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Loads a page of audit entries matching the filter, ordered by timestamp DESC.
  /// Pass [startAfter] = the last [DocumentSnapshot] from the previous page to
  /// continue.
  Future<({List<AuditEntry> entries, DocumentSnapshot? cursor})>
      fetchPage({
    required AuditQueryFilter filter,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _db.collection('staff_audit_logs');

    // Apply equality filters first; Firestore composite indexes already cover
    // each combined with timestamp DESC.
    if (filter.staffUid != null && filter.staffUid!.isNotEmpty) {
      q = q.where('staffUid', isEqualTo: filter.staffUid);
    }
    if (filter.action != null && filter.action!.isNotEmpty) {
      q = q.where('action', isEqualTo: filter.action);
    }
    if (filter.targetId != null && filter.targetId!.isNotEmpty) {
      q = q.where('targetId', isEqualTo: filter.targetId);
    }

    // Range filters on timestamp.
    if (filter.from != null) {
      q = q.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(filter.from!));
    }
    if (filter.to != null) {
      q = q.where('timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(filter.to!));
    }

    q = q.orderBy('timestamp', descending: true).limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snap = await q.get();
    final entries =
        snap.docs.map((d) => AuditEntry.fromFirestore(d)).toList();
    final cursor = snap.docs.isEmpty ? null : snap.docs.last;
    return (entries: entries, cursor: cursor);
  }

  /// Distinct action values across recent audit entries — used to populate the
  /// action-filter dropdown. Cheap because Atlas only emits a small set.
  Future<List<String>> distinctRecentActions({int sample = 200}) async {
    final snap = await _db
        .collection('staff_audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(sample)
        .get();
    final s = <String>{};
    for (final d in snap.docs) {
      final a = d.data()['action'];
      if (a is String) s.add(a);
    }
    return s.toList()..sort();
  }
}
