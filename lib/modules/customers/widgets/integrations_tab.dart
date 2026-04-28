import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/customer_integration_model.dart';
import '../../../core/services/customer_integration_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../widgets/revealable_secret.dart';

/// Integrations tab — lists every webhook integration configured for the
/// customer's org. Each row exposes the API key behind a reveal-with-
/// reason flow that audit-logs to `staff_audit_logs`.
class IntegrationsTab extends StatelessWidget {
  final String orgId;
  final String orgName;
  const IntegrationsTab({
    super.key,
    required this.orgId,
    required this.orgName,
  });

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
        final integrations = snap.data ?? const [];
        if (integrations.isEmpty) {
          return const _Empty();
        }
        // Sort: enabled first, then by name.
        integrations.sort((a, b) {
          if (a.enabled != b.enabled) return a.enabled ? -1 : 1;
          return a.name.compareTo(b.name);
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(integrations: integrations),
            const SizedBox(height: AtlasSpace.lg),
            ...integrations.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: AtlasSpace.md),
                  child: _IntegrationCard(
                    integration: i,
                    orgId: orgId,
                    orgName: orgName,
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<CustomerIntegration> integrations;
  const _SummaryRow({required this.integrations});

  @override
  Widget build(BuildContext context) {
    final total = integrations.length;
    final enabled = integrations.where((i) => i.enabled).length;
    final stale = integrations
        .where((i) => i.enabled && i.healthLabel != 'Healthy')
        .length;
    return Row(
      children: [
        _Tile(
          label: 'Total integrations',
          value: '$total',
          color: AtlasColors.textPrimary,
        ),
        const SizedBox(width: AtlasSpace.md),
        _Tile(
          label: 'Enabled',
          value: '$enabled',
          color: AtlasColors.success,
        ),
        const SizedBox(width: AtlasSpace.md),
        _Tile(
          label: 'Stale or idle',
          value: '$stale',
          color: stale == 0 ? AtlasColors.success : AtlasColors.warning,
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Tile({
    required this.label,
    required this.value,
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
          ],
        ),
      ),
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  final CustomerIntegration integration;
  final String orgId;
  final String orgName;
  const _IntegrationCard({
    required this.integration,
    required this.orgId,
    required this.orgName,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy HH:mm');
    final statusColor = !integration.enabled
        ? AtlasColors.textMuted
        : switch (integration.healthLabel) {
            'Healthy' => AtlasColors.success,
            'Stale' => AtlasColors.warning,
            'Idle' || 'Never received' => AtlasColors.textMuted,
            _ => AtlasColors.textMuted,
          };
    return Container(
      padding: const EdgeInsets.all(AtlasSpace.lg),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
        boxShadow: AtlasElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AtlasColors.accentSoft,
                  borderRadius: BorderRadius.circular(AtlasRadius.sm),
                ),
                alignment: Alignment.center,
                child: Text(
                  _providerInitial(integration.provider),
                  style: const TextStyle(
                    color: AtlasColors.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            integration.name.isNotEmpty
                                ? integration.name
                                : '(unnamed)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AtlasColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AtlasColors.pillNeutral,
                            borderRadius:
                                BorderRadius.circular(AtlasRadius.round),
                          ),
                          child: Text(
                            integration.provider.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AtlasColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (integration.teamName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Team · ${integration.teamName}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AtlasColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _StatusPill(
                color: statusColor,
                label: integration.enabled
                    ? integration.healthLabel
                    : 'Disabled',
              ),
            ],
          ),
          const SizedBox(height: AtlasSpace.md),
          const Divider(height: 1, color: AtlasColors.divider),
          const SizedBox(height: AtlasSpace.md),
          _kv(
            'API key',
            RevealableSecret(
              value: integration.apiKey,
              label: 'API key for "${integration.name}"',
              targetType: 'integration',
              targetId: integration.id,
              targetDisplay: '${integration.name} (${integration.provider})',
            ),
          ),
          if (integration.defaultSeverity != null)
            _kv(
              'Default severity',
              Text(
                integration.defaultSeverity!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AtlasColors.textPrimary,
                ),
              ),
            ),
          _kv(
            'Events received',
            Text(
              '${integration.eventCount}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AtlasColors.textPrimary,
              ),
            ),
          ),
          _kv(
            'Last received',
            Text(
              integration.lastReceivedAt == null
                  ? 'never'
                  : fmt.format(integration.lastReceivedAt!),
              style: const TextStyle(
                fontSize: 12.5,
                color: AtlasColors.textPrimary,
              ),
            ),
          ),
          if (integration.createdAt != null)
            _kv(
              'Created',
              Text(
                '${fmt.format(integration.createdAt!)}'
                '${integration.createdBy != null ? " by ${integration.createdBy}" : ""}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AtlasColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _providerInitial(String p) {
    if (p.isEmpty) return '?';
    final first = p[0].toUpperCase();
    return first;
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AtlasRadius.round),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

Widget _kv(String label, Widget value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AtlasColors.textMuted,
            ),
          ),
        ),
        Expanded(child: value),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();
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
          Icon(Icons.extension_off_outlined,
              size: 28, color: AtlasColors.textMuted),
          SizedBox(height: 8),
          Text('No integrations configured for this organization yet.',
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
        'Failed to load integrations: $message',
        style: const TextStyle(color: AtlasColors.danger, fontSize: 12),
      ),
    );
  }
}
