import 'package:flutter/material.dart';

import '../../../core/models/customer_org_model.dart';
import '../../../core/models/customer_pagers_models.dart';
import '../../../core/services/customer_pagers_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../utils/staff_redirect.dart';
import 'snapshot_redirect_card.dart';

/// Teams sub-tab — snapshot pattern. Lists every team in the org with
/// member count + inbox + a redirect button into the customer app
/// (where staff can browse member management read-only).
class PagersTeamsSubTab extends StatelessWidget {
  final CustomerOrg org;
  const PagersTeamsSubTab({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CustomerTeam>>(
      stream: CustomerPagersService.instance.watchTeams(org.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final teams = snap.data ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (teams.isEmpty)
              const _Empty()
            else
              _Grid(teams: teams, org: org),
            const SizedBox(height: AtlasSpace.lg),
            SnapshotRedirectCard(
              title: 'Browse team configuration',
              subtitle:
                  'Member management, inboxes, routing rules, and service bindings live in the customer app — open in staff (read-only) view.',
              buttonLabel: 'Open Teams in customer view',
              onTap: () => StaffRedirect.open(
                orgId: org.id,
                orgName: org.name,
                subPath: '/teams',
                auditAction: 'OPENED_CUSTOMER_TEAMS',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Grid extends StatelessWidget {
  final List<CustomerTeam> teams;
  final CustomerOrg org;
  const _Grid({required this.teams, required this.org});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 1100
          ? 3
          : c.maxWidth > 720
              ? 2
              : 1;
      return Wrap(
        spacing: AtlasSpace.md,
        runSpacing: AtlasSpace.md,
        children: teams.map((t) {
          final w = (c.maxWidth - (cols - 1) * AtlasSpace.md) / cols;
          return SizedBox(
            width: w,
            child: _Card(team: t),
          );
        }).toList(),
      );
    });
  }
}

class _Card extends StatelessWidget {
  final CustomerTeam team;
  const _Card({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AtlasSpace.lg),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AtlasColors.accentSoft,
                  borderRadius: BorderRadius.circular(AtlasRadius.sm),
                ),
                alignment: Alignment.center,
                child: Text(
                  team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AtlasColors.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  team.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AtlasColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _kv('Members', '${team.memberCount}'),
          if (team.inboxAddress.isNotEmpty)
            _kv('Inbox', team.inboxAddress, mono: true),
          if (team.aliases.isNotEmpty)
            _kv('Aliases', team.aliases.join(', '), mono: true),
          if (team.description != null && team.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              team.description!,
              style: const TextStyle(
                fontSize: 12,
                color: AtlasColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AtlasColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontFamily: mono ? 'monospace' : null,
                color: AtlasColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => const _StubBox(
        icon: Icons.group_outlined,
        message: 'No teams configured for this organization yet.',
      );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _StubBox extends StatelessWidget {
  final IconData icon;
  final String message;
  const _StubBox({required this.icon, required this.message});
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
          Icon(icon, size: 28, color: AtlasColors.textMuted),
          const SizedBox(height: 8),
          Text(message, style: AtlasText.smallMuted),
        ],
      ),
    );
  }
}
