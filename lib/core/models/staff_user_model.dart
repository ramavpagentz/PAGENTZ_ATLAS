import 'package:cloud_firestore/cloud_firestore.dart';

/// Staff role hierarchy. Higher values = more permissions.
enum StaffRole {
  l1Support('l1_support', 'L1 Support', 1),
  l2Support('l2_support', 'L2 Support', 2),
  engineer('engineer', 'Engineer', 3),
  admin('admin', 'Admin', 4),
  owner('owner', 'Owner', 5);

  final String id;
  final String label;
  final int level;
  const StaffRole(this.id, this.label, this.level);

  static StaffRole fromId(String? id) {
    return StaffRole.values.firstWhere(
      (r) => r.id == id,
      orElse: () => StaffRole.l1Support,
    );
  }

  bool isAtLeast(StaffRole other) => level >= other.level;
}

/// Represents a staff user in the system.
/// Lives in the same `users/{uid}` collection as customers, distinguished by `isAtlas: true`.
class StaffUser {
  final String uid;
  final String email;
  final String displayName;
  final bool isAtlas;
  final StaffRole role;
  final bool mfaEnrolled;
  final DateTime? lastLoginAt;
  final String? lastLoginIp;
  final bool disabled;
  final DateTime? staffJoinedAt;
  final DateTime? passwordChangedAt;

  const StaffUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.isAtlas,
    required this.role,
    required this.mfaEnrolled,
    this.lastLoginAt,
    this.lastLoginIp,
    this.disabled = false,
    this.staffJoinedAt,
    this.passwordChangedAt,
  });

  factory StaffUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StaffUser(
      uid: doc.id,
      email: (data['email'] ?? '') as String,
      displayName: (data['displayName'] ?? data['fullName'] ?? '') as String,
      isAtlas: (data['isAtlas'] ?? false) as bool,
      role: StaffRole.fromId(data['staffRole'] as String?),
      mfaEnrolled: (data['mfaEnrolled'] ?? false) as bool,
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      lastLoginIp: data['lastLoginIp'] as String?,
      disabled: (data['disabled'] ?? false) as bool,
      staffJoinedAt: (data['staffJoinedAt'] as Timestamp?)?.toDate(),
      passwordChangedAt:
          (data['passwordChangedAt'] as Timestamp?)?.toDate() ??
              (data['staffJoinedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// True if this user can log into Atlas at all.
  bool get canAccessAtlas => isAtlas && !disabled;

  /// True if password is older than the rotation threshold (defaults to 90d).
  bool passwordExpired({Duration maxAge = const Duration(days: 90)}) {
    final lastChanged = passwordChangedAt;
    if (lastChanged == null) return false;
    return DateTime.now().difference(lastChanged) > maxAge;
  }
}
