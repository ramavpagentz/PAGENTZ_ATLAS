import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_org_model.dart';

/// Reads customer organization data from the shared `organizations` collection.
class CustomerService {
  CustomerService._();
  static final instance = CustomerService._();

  final _db = FirebaseFirestore.instance;

  /// Stream of all organizations, ordered by most recently created.
  /// Atlas users (staff) can read all orgs per Firestore rules.
  Stream<List<CustomerOrg>> watchOrganizations() {
    return _db
        .collection('organizations')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CustomerOrg.fromFirestore(d)).toList());
  }

  Future<CustomerOrg?> getOrganization(String orgId) async {
    final doc = await _db.collection('organizations').doc(orgId).get();
    if (!doc.exists) return null;

    // Best-effort member count.
    int memberCount = 0;
    try {
      final members = await _db
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .count()
          .get();
      memberCount = members.count ?? 0;
    } catch (_) {}

    return CustomerOrg.fromFirestore(doc, memberCount: memberCount);
  }

  /// Members of an organization. Returns user docs.
  Stream<List<Map<String, dynamic>>> watchOrgMembers(String orgId) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }
}
