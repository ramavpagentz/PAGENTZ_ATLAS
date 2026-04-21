import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/organization_model.dart';

class CustomerService {
  CustomerService._();
  static final instance = CustomerService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<List<Organization>> listOrganizations() async {
    final snap = await _db
        .collection('organizations')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => Organization.fromFirestore(d)).toList();
  }

  Future<Organization?> getOrganization(String orgId) async {
    final doc = await _db.collection('organizations').doc(orgId).get();
    if (!doc.exists) return null;
    return Organization.fromFirestore(doc);
  }

  Future<List<OrgMember>> listMembers(String orgId) async {
    final snap = await _db
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .get();
    return snap.docs.map((d) => OrgMember.fromFirestore(d)).toList();
  }

  Future<int> countMembers(String orgId) async {
    final agg = await _db
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .count()
        .get();
    return agg.count ?? 0;
  }
}
