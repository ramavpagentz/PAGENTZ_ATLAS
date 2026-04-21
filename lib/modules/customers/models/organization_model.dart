import 'package:cloud_firestore/cloud_firestore.dart';

class Organization {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? phoneExtension;
  final String? industry;
  final String? website;
  final String? address;
  final int? numberOfEmployees;
  final String? ownerUid;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Organization({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.phoneExtension,
    this.industry,
    this.website,
    this.address,
    this.numberOfEmployees,
    this.ownerUid,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Organization.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Organization(
      id: doc.id,
      name: (d['name'] ?? '(unnamed)') as String,
      email: d['email'] as String?,
      phone: d['phone'] as String?,
      phoneExtension: d['phoneExtension'] as String?,
      industry: d['industry'] as String?,
      website: d['website'] as String?,
      address: d['address'] as String?,
      numberOfEmployees: (d['numberOfEmployees'] as num?)?.toInt(),
      ownerUid: d['ownerUid'] as String?,
      status: d['status'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class OrgMember {
  final String id;
  final String orgId;
  final String? userId;
  final String? email;
  final String? role;
  final String? status;
  final bool? used;
  final DateTime? invitedAt;
  final DateTime? acceptedAt;
  final String? invitedBy;
  final Map<String, dynamic>? modulePerms;

  OrgMember({
    required this.id,
    required this.orgId,
    this.userId,
    this.email,
    this.role,
    this.status,
    this.used,
    this.invitedAt,
    this.acceptedAt,
    this.invitedBy,
    this.modulePerms,
  });

  factory OrgMember.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return OrgMember(
      id: doc.id,
      orgId: (d['orgId'] ?? '') as String,
      userId: d['userId'] as String?,
      email: d['email'] as String?,
      role: d['role'] as String?,
      status: d['status'] as String?,
      used: d['used'] as bool?,
      invitedAt: (d['invitedAt'] as Timestamp?)?.toDate(),
      acceptedAt: (d['acceptedAt'] as Timestamp?)?.toDate(),
      invitedBy: d['invitedBy'] as String?,
      modulePerms: d['modulePerms'] as Map<String, dynamic>?,
    );
  }

  bool get isAccepted =>
      acceptedAt != null || status == 'accepted' || used == true;
}
