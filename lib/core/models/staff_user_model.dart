import 'package:cloud_firestore/cloud_firestore.dart';

enum StaffRole { l1Support, l2Support, engineer, admin, owner }

extension StaffRoleX on StaffRole {
  String get value {
    switch (this) {
      case StaffRole.l1Support:
        return 'l1_support';
      case StaffRole.l2Support:
        return 'l2_support';
      case StaffRole.engineer:
        return 'engineer';
      case StaffRole.admin:
        return 'admin';
      case StaffRole.owner:
        return 'owner';
    }
  }

  static StaffRole fromString(String s) {
    switch (s) {
      case 'l1_support':
        return StaffRole.l1Support;
      case 'l2_support':
        return StaffRole.l2Support;
      case 'engineer':
        return StaffRole.engineer;
      case 'admin':
        return StaffRole.admin;
      case 'owner':
        return StaffRole.owner;
      default:
        throw ArgumentError('Unknown staff role: $s');
    }
  }
}

class StaffUser {
  final String uid;
  final String email;
  final String displayName;
  final bool isStaff;
  final StaffRole? staffRole;
  final String? staffTenantId;
  final DateTime? staffJoinedAt;
  final bool mfaEnrolled;
  final bool disabled;

  StaffUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.isStaff,
    this.staffRole,
    this.staffTenantId,
    this.staffJoinedAt,
    required this.mfaEnrolled,
    required this.disabled,
  });

  factory StaffUser.fromFirestore(String uid, Map<String, dynamic> data) {
    return StaffUser(
      uid: uid,
      email: (data['email'] ?? '') as String,
      displayName: (data['displayName'] ?? '') as String,
      isStaff: (data['isStaff'] ?? false) as bool,
      staffRole: data['staffRole'] is String
          ? StaffRoleX.fromString(data['staffRole'] as String)
          : null,
      staffTenantId: data['staffTenantId'] as String?,
      staffJoinedAt: (data['staffJoinedAt'] as Timestamp?)?.toDate(),
      mfaEnrolled: (data['mfaEnrolled'] ?? false) as bool,
      disabled: (data['disabled'] ?? false) as bool,
    );
  }
}
