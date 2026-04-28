import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/customer_integration_model.dart';
import '../../../core/services/customer_integration_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';

/// Webhooks sub-tab — surfaces every inbound webhook the customer has
/// configured, plus the summary stats (event count, last received) the
/// schema actually tracks. Per-event delivery history isn't logged in
/// Firestore today, so this is a configuration + freshness view rather
/// than a request-by-request audit.
class PagersWebhooksSubTab extends StatelessWidget {
  final String orgId;
  const PagersWebhooksSubTab({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CustomerIntegration>>(
      stream: CustomerIntegrationService.instance.watchForOrg(orgId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return _ErrorBox(message: snap.error.toString());
        }
        final all = snap.data ?? const <CustomerIntegration>[];
        // Webhooks sub-tab is the same data source as Integrations but framed
        // around freshness/event volume.
        final hooks = [...all]..sort((a, b) {
            final at = a.lastReceivedAt;
            final bt = b.lastReceivedAt;
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(hooks: hooks),
            const SizedBox(height: AtlasSpace.lg),
            const _DataNote(),
            const SizedBox(height: AtlasSpace.md),
            if (hooks.isEmpty)
              const _EmptyBox()
            else
              _DeliveryTable(hooks: hooks),
          ],
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<CustomerIntegration> hooks;
  const _SummaryRow({required this.hooks});

  @override
  Widget build(BuildContext context) {
    final total = hooks.length;
    final enabled = hooks.where((h) => h.enabled).length;
    final receivedRecently = hooks.where((h) {
      final t = h.lastReceivedAt;
      return t != null && DateTime.now().difference(t).inHours < 24;
    }).length;
    final totalEvents =
        hooks.fold<int>(0, (sum, h) => sum + h.eventCount);

    return Row(
      children: [
        _Tile(
          label: 'Webhooks',
          value: '$total',
          sub: '$enabled enabled',
          color: AtlasColors.textPrimary,
        ),
        const SizedBox(width: AtlasSpace.md),
        _Tile(
          label: 'Active in 24h',
          value: '$receivedRecently',
          sub: 'received an event',
          color: receivedRecently > 0
              ? AtlasColors.success
              : AtlasColors.textMuted,
        ),
        const SizedBox(width: AtlasSpace.md),
        _Tile(
          label: 'Total events',
          value: '$totalEvents',
          sub: 'lifetime, all webhooks',
          color: AtlasColors.info,
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  const _Tile({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AtlasSpace.lg),
        decoration: BoxDecoration(
          color: AtlasColors.cardBg,
          border: Border.all(color: AtlasColors.cardBorder),
          borderRadius: BorderRadius.circular(AtlasRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AtlasColors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(
                fontSize: 11,
                color: AtlasColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataNote extends StatelessWidget {
  const _DataNote();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AtlasSpace.lg, vertical: AtlasSpace.md),
      decoration: BoxDecoration(
        color: AtlasColors.warningSoft,
        border: Border.all(color: AtlasColors.warning.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AtlasRadius.md),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: AtlasColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Per-delivery history (success / failure of each individual '
              'webhook hit) is not currently logged in Firestore. This view '
              'shows configuration + freshness signals (lastReceivedAt + '
              'eventCount). For deep delivery debugging, check the customer\'s '
              'monitoring tool side or add a `webhook_deliveries` collection.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF78350F),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryTable extends StatelessWidget {
  final List<CustomerIntegration> hooks;
  const _DeliveryTable({required this.hooks});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, HH:mm');
    return Container(
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: const BoxDecoration(
              color: AtlasColors.tableHeaderBg,
              border: Border(
                bottom: BorderSide(color: AtlasColors.tableBorder),
              ),
            ),
            child: Row(
              children: const [
                Expanded(flex: 3, child: _HCell('Webhook')),
                Expanded(flex: 2, child: _HCell('Provider · Team')),
                SizedBox(width: 140, child: _HCell('Last received')),
                SizedBox(width: 80, child: _HCell('Events')),
                SizedBox(width: 90, child: _HCell('Status')),
              ],
            ),
          ),
          for (var i = 0; i < hooks.length; i++)
            _Row(
              hook: hooks[i],
              isLast: i == hooks.length - 1,
              fmt: fmt,
            ),
        ],
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  final String label;
  const _HCell(this.label);
  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AtlasColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final CustomerIntegration hook;
  final bool isLast;
  final DateFormat fmt;
  const _Row({
    required this.hook,
    required this.isLast,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final freshness = _freshness(hook);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AtlasColors.cardBorder),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hook.name.isNotEmpty ? hook.name : '(unnamed webhook)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AtlasColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'id: ${hook.id}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                    color: AtlasColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${hook.provider}${hook.teamName.isNotEmpty ? " · ${hook.teamName}" : ""}',
              style: const TextStyle(
                fontSize: 12,
                color: AtlasColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              hook.lastReceivedAt == null
                  ? 'never'
                  : fmt.format(hook.lastReceivedAt!),
              style: TextStyle(
                fontSize: 12,
                color: hook.lastReceivedAt == null
                    ? AtlasColors.textMuted
                    : AtlasColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '${hook.eventCount}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AtlasColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: freshness.$2.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AtlasRadius.round),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                freshness.$1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: freshness.$2,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _freshness(CustomerIntegration h) {
    if (!h.enabled) return ('Disabled', AtlasColors.textMuted);
    final t = h.lastReceivedAt;
    if (t == null) return ('Never', AtlasColors.textMuted);
    final hoursAgo = DateTime.now().difference(t).inHours;
    if (hoursAgo < 24) return ('Active', AtlasColors.success);
    if (hoursAgo < 24 * 7) return ('Stale', AtlasColors.warning);
    return ('Idle', AtlasColors.textMuted);
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.webhook_outlined,
              size: 28, color: AtlasColors.textMuted),
          SizedBox(height: 8),
          Text('No webhooks configured for this organization yet.',
              style: AtlasText.smallMuted),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AtlasColors.dangerSoft,
        border: Border.all(color: AtlasColors.danger),
        borderRadius: BorderRadius.circular(AtlasRadius.md),
      ),
      child: Text(
        'Failed to load webhooks: $message',
        style: const TextStyle(color: AtlasColors.danger, fontSize: 12),
      ),
    );
  }
}
