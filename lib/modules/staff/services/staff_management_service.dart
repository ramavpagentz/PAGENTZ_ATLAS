import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/staff_listing_model.dart';

class CreateStaffResult {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String tempPassword;

  const CreateStaffResult({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.tempPassword,
  });
}

class ResetPasswordResult {
  final String uid;
  final String email;
  final String resetLink;

  const ResetPasswordResult({
    required this.uid,
    required this.email,
    required this.resetLink,
  });
}

class StaffManagementService {
  StaffManagementService._();
  static final instance = StaffManagementService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseFunctions get _fns => FirebaseFunctions.instance;

  /// Lists all users with `isStaff=true`. Read directly from Firestore (rules
  /// allow `read` on /users/{uid} for any authenticated user).
  Future<List<StaffListing>> listStaff() async {
    final snap = await _db
        .collection('users')
        .where('isStaff', isEqualTo: true)
        .get();
    final list = snap.docs.map((d) => StaffListing.fromFirestore(d)).toList();
    list.sort((a, b) => a.email.compareTo(b.email));
    return list;
  }

  Future<CreateStaffResult> createStaff({
    required String email,
    required String displayName,
    required String role,
    String? reason,
  }) async {
    final callable = _fns.httpsCallable('atlasCreateStaff');
    final res = await callable.call<Map<String, dynamic>>({
      'email': email,
      'displayName': displayName,
      'role': role,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    final d = Map<String, dynamic>.from(res.data);
    return CreateStaffResult(
      uid: d['uid'] as String,
      email: d['email'] as String,
      displayName: d['displayName'] as String,
      role: d['role'] as String,
      tempPassword: d['tempPassword'] as String,
    );
  }

  Future<bool> updateStaffRole({
    required String uid,
    required String newRole,
    String? reason,
  }) async {
    final callable = _fns.httpsCallable('atlasUpdateStaffRole');
    final res = await callable.call<Map<String, dynamic>>({
      'uid': uid,
      'newRole': newRole,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    final d = Map<String, dynamic>.from(res.data);
    return (d['changed'] as bool?) ?? false;
  }

  Future<void> setStaffDisabled({
    required String uid,
    required bool disabled,
    String? reason,
  }) async {
    final callable = _fns.httpsCallable('atlasSetStaffDisabled');
    await callable.call<Map<String, dynamic>>({
      'uid': uid,
      'disabled': disabled,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  Future<ResetPasswordResult> resetStaffPassword({
    required String uid,
    String? reason,
  }) async {
    final callable = _fns.httpsCallable('atlasResetStaffPassword');
    final res = await callable.call<Map<String, dynamic>>({
      'uid': uid,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    final d = Map<String, dynamic>.from(res.data);
    return ResetPasswordResult(
      uid: d['uid'] as String,
      email: d['email'] as String,
      resetLink: d['resetLink'] as String,
    );
  }
}
