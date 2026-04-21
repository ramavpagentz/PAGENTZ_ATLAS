import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/atlas_config.dart';
import '../models/staff_user_model.dart';

class StaffAuthService {
  StaffAuthService._();
  static final instance = StaffAuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  void configureTenant() {
    _auth.tenantId = AtlasConfig.staffTenantId;
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<StaffUser?> fetchStaffUserDoc(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return StaffUser.fromFirestore(uid, snap.data() ?? const {});
  }

  Future<void> markMfaEnrolled(String uid) {
    return _db.collection('users').doc(uid).update({'mfaEnrolled': true});
  }
}
