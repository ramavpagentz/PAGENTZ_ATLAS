import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_incident_model.dart';

/// Read-only access to the customer app's `inbound_emails` collection
/// (which the customer app uses as its incidents store).
///
/// All queries are scoped to a single `orgId`. Atlas staff can read these
/// because Firestore rules grant reads to authenticated callers — writes
/// are blocked at the rules layer for staff sessions.
class CustomerIncidentService {
  CustomerIncidentService._();
  static final instance = CustomerIncidentService._();

  static const _collection = 'inbound_emails';
  final _db = FirebaseFirestore.instance;

  /// Stream the most recent incidents for an org, newest first.
  Stream<List<CustomerIncident>> watchForOrg(
    String orgId, {
    int limit = 50,
  }) {
    return _db
        .collection(_collection)
        .where('orgId', isEqualTo: orgId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(CustomerIncident.fromDoc).toList());
  }

  /// Single incident by id.
  Future<CustomerIncident?> getById(String incidentId) async {
    final doc = await _db.collection(_collection).doc(incidentId).get();
    if (!doc.exists) return null;
    return CustomerIncident.fromDoc(doc);
  }

  /// Stream notes (responder comments) for an incident.
  Stream<List<CustomerIncidentNote>> watchNotes(String incidentId) {
    return _db
        .collection(_collection)
        .doc(incidentId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CustomerIncidentNote.fromDoc).toList());
  }

  /// Aggregated counts (open / acked / resolved) for the last `windowDays`.
  /// Used by the Health tab and the Pagers tab badge.
  ///
  /// Explicit `orderBy('createdAt', descending: true)` so the query reuses
  /// the same `(orgId asc, createdAt desc)` composite index that the
  /// `watchForOrg` stream uses — no second index direction needed.
  Future<Map<String, int>> countsByStatus({
    required String orgId,
    int windowDays = 30,
  }) async {
    final since = DateTime.now().subtract(Duration(days: windowDays));
    final snap = await _db
        .collection(_collection)
        .where('orgId', isEqualTo: orgId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .get();

    final counts = <String, int>{'open': 0, 'ack': 0, 'resolved': 0};
    for (final d in snap.docs) {
      final s = (d.data()['status'] as String?) ?? 'open';
      counts.update(s, (v) => v + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}
