import 'package:cloud_firestore/cloud_firestore.dart';

/// A reusable reply template that staff can insert into ticket replies.
/// Admins manage these from Staff Management → Templates.
class CannedResponse {
  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime? createdAt;
  final String? createdByEmail;

  const CannedResponse({
    required this.id,
    required this.title,
    required this.body,
    this.tags = const [],
    this.createdAt,
    this.createdByEmail,
  });

  factory CannedResponse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CannedResponse(
      id: doc.id,
      title: (data['title'] ?? 'Untitled') as String,
      body: (data['body'] ?? '') as String,
      tags: ((data['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdByEmail: data['createdByEmail'] as String?,
    );
  }

  Map<String, dynamic> toMap({bool includeCreated = false}) {
    return {
      'title': title.trim(),
      'body': body.trim(),
      'tags': tags,
      if (includeCreated) 'createdAt': FieldValue.serverTimestamp(),
      if (createdByEmail != null) 'createdByEmail': createdByEmail,
    };
  }
}
