import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/customer_org_model.dart';
import '../../../core/services/audit_log_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';

/// Subscription / Billing tab — surfaces the customer's plan + seats +
/// renewal info from the `subscription` map field on the org doc, plus
/// a "Open in Stripe" link for staff with the customer ID.
///
/// Stripe-side data (invoices, payment method, MRR) is intentionally
/// not pulled here — it would require a server-side Cloud Function with
/// a Stripe secret key. For now staff get a one-click link out to the
/// Stripe dashboard for the customer ID.
class SubscriptionTab extends StatelessWidget {
  final CustomerOrg org;
  const SubscriptionTab({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('organizations')
          .doc(org.id)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snap.data?.data() ?? const <String, dynamic>{};
        final sub = data['subscription'];
        final subMap = sub is Map ? Map<String, dynamic>.from(sub) : null;
        final fmt = DateFormat('MMM d, yyyy');

        final plan = (subMap?['plan'] ?? data['plan'] ?? 'free') as String;
        final status =
            (subMap?['status'] ?? data['planStatus'] ?? 'active') as String;
        final seats = (subMap?['seats'] as num?)?.toInt();
        final stripeCustomerId = subMap?['stripeCustomerId'] as String?;
        final stripeSubscriptionId = subMap?['stripeSubscriptionId'] as String?;
        final stripePriceId = subMap?['stripePriceId'] as String?;
        final periodStart = _toDate(subMap?['currentPeriodStart']);
        final periodEnd = _toDate(subMap?['currentPeriodEnd']);
        final cancelAtPeriodEnd = subMap?['cancelAtPeriodEnd'] == true;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PlanCard(
              plan: plan,
              status: status,
              seats: seats,
              memberCount: org.memberCount,
              periodEnd: periodEnd,
              cancelAtPeriodEnd: cancelAtPeriodEnd,
            ),
            const SizedBox(height: AtlasSpace.lg),
            Container(
              padding: const EdgeInsets.all(AtlasSpace.xl),
              decoration: BoxDecoration(
                color: AtlasColors.cardBg,
                border: Border.all(color: AtlasColors.cardBorder),
                borderRadius: BorderRadius.circular(AtlasRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Subscription detail', style: AtlasText.h3),
                  const SizedBox(height: AtlasSpace.md),
                  _kv('Plan', plan.toUpperCase()),
                  _kv('Status', status.toUpperCase()),
                  if (seats != null) _kv('Seats', '$seats'),
                  _kv('Member count', '${org.memberCount}'),
                  if (periodStart != null)
                    _kv('Current period start', fmt.format(periodStart)),
                  if (periodEnd != null)
                    _kv(
                      cancelAtPeriodEnd ? 'Cancels on' : 'Renews on',
                      fmt.format(periodEnd),
                    ),
                  if (stripePriceId != null)
                    _kv('Stripe price id', stripePriceId, mono: true),
                  if (stripeSubscriptionId != null)
                    _kv('Stripe subscription id', stripeSubscriptionId,
                        mono: true),
                  if (stripeCustomerId != null)
                    _kv('Stripe customer id', stripeCustomerId, mono: true),
                ],
              ),
            ),
            const SizedBox(height: AtlasSpace.lg),
            if (stripeCustomerId != null)
              _StripePortalCard(
                stripeCustomerId: stripeCustomerId,
                orgId: org.id,
                orgName: org.name,
              )
            else
              _NoStripeCard(),
          ],
        );
      },
    );
  }
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

class _PlanCard extends StatelessWidget {
  final String plan;
  final String status;
  final int? seats;
  final int memberCount;
  final DateTime? periodEnd;
  final bool cancelAtPeriodEnd;
  const _PlanCard({
    required this.plan,
    required this.status,
    required this.memberCount,
    required this.cancelAtPeriodEnd,
    this.seats,
    this.periodEnd,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (plan) {
      'premium' => const Color(0xFF7C3AED),
      'plus' => AtlasColors.info,
      _ => AtlasColors.textMuted,
    };
    final statusColor = switch (status) {
      'active' => AtlasColors.success,
      'trialing' => AtlasColors.info,
      'past_due' => AtlasColors.warning,
      'canceled' || 'cancelled' => AtlasColors.danger,
      _ => AtlasColors.textMuted,
    };
    final fmt = DateFormat('MMM d, yyyy');

    final seatsLine = (seats != null && seats! > 0)
        ? '$memberCount / $seats seats used'
        : '$memberCount members';

    return Container(
      padding: const EdgeInsets.all(AtlasSpace.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.10),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AtlasRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan.toUpperCase(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AtlasRadius.round),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (cancelAtPeriodEnd) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AtlasColors.dangerSoft,
                    borderRadius: BorderRadius.circular(AtlasRadius.round),
                  ),
                  child: const Text(
                    'CANCEL AT PERIOD END',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AtlasColors.danger,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            seatsLine,
            style: const TextStyle(
              fontSize: 13,
              color: AtlasColors.textSecondary,
            ),
          ),
          if (periodEnd != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                cancelAtPeriodEnd
                    ? 'Cancels on ${fmt.format(periodEnd!)}'
                    : 'Renews on ${fmt.format(periodEnd!)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AtlasColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StripePortalCard extends StatelessWidget {
  final String stripeCustomerId;
  final String orgId;
  final String orgName;
  const _StripePortalCard({
    required this.stripeCustomerId,
    required this.orgId,
    required this.orgName,
  });

  Future<void> _openStripe() async {
    AuditLogService.instance.log(
      action: 'OPENED_STRIPE_DASHBOARD',
      targetType: 'org',
      targetId: orgId,
      targetDisplay: orgName,
      changes: {'stripeCustomerId': stripeCustomerId},
    );
    final url = Uri.parse(
      'https://dashboard.stripe.com/customers/$stripeCustomerId',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AtlasSpace.xl),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Need to view invoices, payment method, or MRR?',
                    style: AtlasText.h3),
                SizedBox(height: 4),
                Text(
                  'Atlas links straight to the Stripe dashboard for this customer. '
                  'The redirect is audit-logged.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AtlasColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AtlasSpace.lg),
          ElevatedButton.icon(
            onPressed: _openStripe,
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text('Open in Stripe'),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoStripeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AtlasSpace.xl),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AtlasColors.textMuted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No Stripe customer id is set for this org — they may be on the '
              'free plan or never started a paid subscription.',
              style: TextStyle(
                fontSize: 12.5,
                color: AtlasColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _kv(String label, String value, {bool mono = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 200,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AtlasColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(
              fontSize: 12.5,
              color: AtlasColors.textPrimary,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    ),
  );
}
