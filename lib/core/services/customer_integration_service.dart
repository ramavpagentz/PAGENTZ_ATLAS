import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_integration_model.dart';

/// Read-only access to the customer's integrations doc at
/// `organizations/{orgId}/settings/integrations`. The doc holds an array
/// `webhooks: [WebhookConfig...]` plus may grow with other connectors
/// (Slack, ConnectWise) in the future.
class CustomerIntegrationService {
  CustomerIntegrationService._();
  static final instance = CustomerIntegrationService._();

  final _db = FirebaseFirestore.instance;

  Stream<List<CustomerIntegration>> watchForOrg(String orgId) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('settings')
        .doc('integrations')
        .snapshots()
        .map((doc) {
      final data = doc.data() ?? const <String, dynamic>{};
      final raw = data['webhooks'];
      if (raw is! List) return const <CustomerIntegration>[];
      return raw
          .whereType<Map>()
          .map((m) =>
              CustomerIntegration.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    });
  }
}
