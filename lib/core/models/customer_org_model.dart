import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight view of a customer organization, optimized for the Atlas
/// directory and detail screens. Reads from the existing `organizations`
/// collection that the customer app writes to.
class CustomerOrg {
  final String id;
  final String name;
  final String? email;
  final String? website;
  final String? industry;
  final int? numberOfEmployees;
  final String? plan;          // "free" | "plus" | "premium" — from subscription doc
  final String? planStatus;    // "active" | "past_due" | "cancelled"
  final int memberCount;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final bool disabled;

  const CustomerOrg({
    required this.id,
    required this.name,
    this.email,
    this.website,
    this.industry,
    this.numberOfEmployees,
    this.plan,
    this.planStatus,
    this.memberCount = 0,
    this.createdAt,
    this.lastActiveAt,
    this.disabled = false,
  });

  factory CustomerOrg.fromFirestore(DocumentSnapshot doc, {int memberCount = 0}) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CustomerOrg(
      id: doc.id,
      name: (data['name'] ?? 'Untitled Org') as String,
      email: data['email'] as String?,
      website: data['website'] as String?,
      industry: data['industry'] as String?,
      numberOfEmployees: data['numberOfEmployees'] as int?,
      plan: data['plan'] as String?,
      planStatus: data['planStatus'] as String?,
      memberCount: memberCount,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
      disabled: (data['disabled'] ?? false) as bool,
    );
  }
}
