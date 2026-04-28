import 'package:flutter/material.dart';

import '../../../core/models/customer_org_model.dart';
import '../../../core/models/customer_pagers_models.dart';
import '../../../core/services/customer_pagers_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../utils/staff_redirect.dart';
import 'snapshot_redirect_card.dart';

/// Policies sub-tab — snapshot pattern. Lists active escalation policies
/// across all teams in the org with level counts. Detailed level / channel
/// configuration lives in the customer app.
class PagersPoliciesSubTab extends StatelessWidget {
  final CustomerOrg org;
  const PagersPoliciesSubTab({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CustomerPolicy>>(
      future: CustomerPagersService.instance.getPoliciesForOrg(org.id),
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
        final policies = snap.data ?? const [];
        final teamsFuture = CustomerPagersService.instance.getTeams(org.id);

        return FutureBuilder<List<CustomerTeam>>(
          future: teamsFuture,
          builder: (context, teamsSnap) {
            final teamMap = <String, String>{
              for (final t in (teamsSnap.data ?? const [])) t.id: t.name,
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (policies.isEmpty)
                  const _EmptyBox(
                    message: 'No escalation policies configured for this org.',
                  )
                else
                  _Table(policies: policies, teamMap: teamMap),
                const SizedBox(height: AtlasSpace.lg),
                SnapshotRedirectCard(
                  title: 'Edit policy detail',
                  subtitle:
                      'Layer/level diagrams, channel mappings, and per-target configuration are in the customer app.',
                  buttonLabel: 'Open Policies in customer view',
                  onTap: () => StaffRedirect.open(
                    orgId: org.id,
                    orgName: org.name,
                    subPath: '/escalationPolicy',
                    auditAction: 'OPENED_CUSTOMER_POLICIES',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Table extends StatelessWidget {
  final List<CustomerPolicy> policies;
  final Map<String, String> teamMap;
  const _Table({required this.policies, required this.teamMap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      child: Column(
        children: [
          const _HeaderRow(),
          ...policies.map((p) => _Row(
                policy: p,
                teamName: teamMap[p.teamId] ?? p.teamId,
              )),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        color: AtlasColors.tableHeaderBg,
        border: Border(bottom: BorderSide(color: AtlasColors.tableBorder)),
      ),
      child: Row(
        children: const [
          Expanded(flex: 3, child: _HCell('Policy')),
          Expanded(flex: 2, child: _HCell('Team')),
          SizedBox(width: 80, child: _HCell('Levels')),
          SizedBox(width: 80, child: _HCell('Status')),
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
  final CustomerPolicy policy;
  final String teamName;
  const _Row({required this.policy, required this.teamName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AtlasColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  policy.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AtlasColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (policy.description != null &&
                    policy.description!.isNotEmpty)
                  Text(
                    policy.description!,
                    style: const TextStyle(
                      fontSize: 11,
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
              teamName,
              style: const TextStyle(
                fontSize: 12,
                color: AtlasColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '${policy.levelCount}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AtlasColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: policy.isActive
                    ? AtlasColors.successSoft
                    : AtlasColors.pillNeutral,
                borderRadius: BorderRadius.circular(AtlasRadius.round),
              ),
              alignment: Alignment.center,
              child: Text(
                policy.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: policy.isActive
                      ? AtlasColors.success
                      : AtlasColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String message;
  const _EmptyBox({required this.message});
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.policy_outlined,
              size: 28, color: AtlasColors.textMuted),
          const SizedBox(height: 8),
          Text(message, style: AtlasText.smallMuted),
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
        'Failed to load policies: $message',
        style: const TextStyle(color: AtlasColors.danger, fontSize: 12),
      ),
    );
  }
}
