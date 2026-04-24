import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/canned_response_model.dart';

class CannedResponseService {
  CannedResponseService._();
  static final instance = CannedResponseService._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('canned_responses');

  Stream<List<CannedResponse>> watchAll() {
    return _col
        .orderBy('title')
        .snapshots()
        .map((s) => s.docs.map(CannedResponse.fromFirestore).toList());
  }

  Future<void> create(CannedResponse tpl) async {
    await _col.add(tpl.toMap(includeCreated: true));
  }

  Future<void> update(String id, CannedResponse tpl) async {
    await _col.doc(id).update(tpl.toMap());
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}
