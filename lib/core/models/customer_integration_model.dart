import 'package:cloud_firestore/cloud_firestore.dart';

/// Read-only Atlas view of a customer's webhook integration. Pulled from
/// `organizations/{orgId}/settings/integrations.webhooks[]`.
class CustomerIntegration {
  final String id;
  final String provider; // 'slack', 'datadog', 'generic', etc.
  final String name;
  final bool enabled;
  final String teamId;
  final String teamName;
  final String apiKey;
  final String? defaultSeverity;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? lastReceivedAt;
  final int eventCount;

  CustomerIntegration({
    required this.id,
    required this.provider,
    required this.name,
    required this.enabled,
    required this.teamId,
    required this.teamName,
    required this.apiKey,
    required this.eventCount,
    this.defaultSeverity,
    this.createdAt,
    this.createdBy,
    this.lastReceivedAt,
  });

  factory CustomerIntegration.fromMap(Map<String, dynamic> m) {
    return CustomerIntegration(
      id: (m['id'] as String?) ?? '',
      provider: (m['provider'] as String?) ?? 'generic',
      name: (m['name'] as String?) ?? '',
      enabled: m['enabled'] != false,
      teamId: (m['teamId'] as String?) ?? '',
      teamName: (m['teamName'] as String?) ?? '',
      apiKey: (m['apiKey'] as String?) ?? '',
      defaultSeverity: m['defaultSeverity'] as String?,
      createdAt: _toDate(m['createdAt']),
      createdBy: m['createdBy'] as String?,
      lastReceivedAt: _toDate(m['lastReceivedAt']),
      eventCount: (m['eventCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Health label based on lastReceivedAt + enabled.
  String get healthLabel {
    if (!enabled) return 'Disabled';
    if (lastReceivedAt == null) return 'Never received';
    final hoursAgo = DateTime.now().difference(lastReceivedAt!).inHours;
    if (hoursAgo < 24) return 'Healthy';
    if (hoursAgo < 24 * 7) return 'Stale';
    return 'Idle';
  }
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
