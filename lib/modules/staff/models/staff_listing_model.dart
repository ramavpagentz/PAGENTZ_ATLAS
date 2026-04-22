import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/staff_user_model.dart';

/// Read-model for the staff management list. Mirrors fields written by
/// atlasCreateStaff / atlasUpdateStaffRole / atlasSetStaffDisabled.
class StaffListing {
  final String uid;
  final String email;
  final String displayName;
  final StaffRole? role;
  final bool disabled;
  final bool mfaEnrolled;
  final DateTime? joinedAt;
  final DateTime? lastLoginAt;
  final String? createdByStaffUid;

  StaffListing({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.disabled,
    required this.mfaEnrolled,
    this.joinedAt,
    this.lastLoginAt,
    this.createdByStaffUid,
  });

  factory StaffListing.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return StaffListing(
      uid: doc.id,
      email: (d['email'] ?? '') as String,
      displayName: (d['displayName'] ?? '') as String,
      role: d['staffRole'] is String
          ? StaffRoleX.fromString(d['staffRole'] as String)
          : null,
      disabled: (d['disabled'] ?? false) as bool,
      mfaEnrolled: (d['mfaEnrolled'] ?? false) as bool,
      joinedAt: (d['staffJoinedAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (d['lastLoginAt'] as Timestamp?)?.toDate(),
      createdByStaffUid: d['createdByStaffUid'] as String?,
    );
  }
}
