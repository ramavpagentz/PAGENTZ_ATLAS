import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/customer_org_model.dart';
import '../../../core/services/customer_incident_service.dart';
import '../../../core/services/customer_pagers_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../widgets/pii_field.dart';

/// Enhanced Overview tab — adds:
///   • 3 stat tiles (members, open incidents, computed health score)
///   • An onboarding-progress card (5-step checklist auto-detected from
///     teams / members / schedules / policies / incidents)
///   • The original org-detail and contact cards.
class OverviewTab extends StatelessWidget {
  final CustomerOrg org;
  const OverviewTab({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatRow(org: org),
        const SizedBox(height: AtlasSpace.lg),
        LayoutBuilder(builder: (context, c) {
          final isWide = c.maxWidth > 760;
          final left = _DetailsCard(org: org);
          final right = _OnboardingCard(org: org);
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: AtlasSpace.lg),
                Expanded(child: right),
              ],
            );
          }
          return Column(children: [
            left,
            const SizedBox(height: AtlasSpace.lg),
            right,
          ]);
        }),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// Stat row (Members / Open incidents / Health)
// ───────────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final CustomerOrg org;
  const _StatRow({required this.org});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: CustomerIncidentService.instance.countsByStatus(orgId: org.id),
      builder: (context, snap) {
        final counts = snap.data ?? const <String, int>{};
        final open = counts['open'] ?? 0;
        final acked =
            (counts['ack'] ?? 0) + (counts['acknowledged'] ?? 0);
        final score = _healthScore(open: open, acked: acked);
        final scoreColor = switch (score) {
          >= 90 => AtlasColors.success,
          >= 70 => AtlasColors.info,
          >= 40 => AtlasColors.warning,
          _ => AtlasColors.danger,
        };
        return Row(
          children: [
            _Tile(
              label: 'Members',
              value: org.memberCount > 0 ? '${org.memberCount}' : '—',
              sub: 'across all roles',
              color: AtlasColors.textPrimary,
            ),
            const SizedBox(width: AtlasSpace.md),
            _Tile(
              label: 'Open incidents',
              value: '$open',
              sub: open == 0 ? 'all clear' : 'needs attention',
              color: open == 0 ? AtlasColors.success : AtlasColors.danger,
            ),
            const SizedBox(width: AtlasSpace.md),
            _Tile(
              label: 'Health score',
              value: '$score',
              sub: 'see Health tab for detail',
              color: scoreColor,
            ),
          ],
        );
      },
    );
  }

  int _healthScore({required int open, required int acked}) {
    var s = 100 - (open * 10) - (acked * 3);
    return s.clamp(0, 100);
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
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
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

// ───────────────────────────────────────────────────────────────────────
// Org details / contact card (original two-card content, single column)
// ───────────────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final CustomerOrg org;
  const _DetailsCard({required this.org});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
        boxShadow: AtlasElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
                AtlasSpace.xl, AtlasSpace.lg, AtlasSpace.xl, AtlasSpace.md),
            child: Text('Organization', style: AtlasText.h3),
          ),
          const Divider(height: 1, color: AtlasColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AtlasSpace.xl, vertical: AtlasSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Name', org.name),
                _row('Industry', org.industry ?? '—'),
                _row('Employees', org.numberOfEmployees?.toString() ?? '—'),
                _row(
                  'Created',
                  org.createdAt != null
                      ? DateFormat('MMM d, yyyy').format(org.createdAt!)
                      : '—',
                ),
                _piiRow(
                  'Email',
                  PiiField(
                    value: org.email,
                    type: PiiType.email,
                    targetType: 'org',
                    targetId: org.id,
                    targetDisplay: org.name,
                  ),
                ),
                _row('Website', org.website ?? '—'),
                _row(
                  'Last activity',
                  org.lastActiveAt == null
                      ? '—'
                      : _relative(org.lastActiveAt!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// Onboarding progress card (auto-detected)
// ───────────────────────────────────────────────────────────────────────

class _OnboardingCard extends StatelessWidget {
  final CustomerOrg org;
  const _OnboardingCard({required this.org});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_OnboardingState>(
      future: _detect(org.id),
      builder: (context, snap) {
        final s = snap.data;
        return Container(
          decoration: BoxDecoration(
            color: AtlasColors.cardBg,
            border: Border.all(color: AtlasColors.cardBorder),
            borderRadius: BorderRadius.circular(AtlasRadius.lg),
            boxShadow: AtlasElevation.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AtlasSpace.xl,
                    AtlasSpace.lg, AtlasSpace.xl, AtlasSpace.md),
                child: Row(
                  children: [
                    const Expanded(
                        child: Text('Onboarding progress', style: AtlasText.h3)),
                    if (s != null)
                      Text(
                        '${s.completedCount} / 5',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: s.isComplete
                              ? AtlasColors.success
                              : AtlasColors.warning,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AtlasColors.divider),
              if (snap.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(AtlasSpace.lg),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (s == null)
                const Padding(
                  padding: EdgeInsets.all(AtlasSpace.lg),
                  child: Text(
                    'Could not load onboarding state.',
                    style: AtlasText.smallMuted,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AtlasSpace.xl, vertical: AtlasSpace.md),
                  child: Column(
                    children: [
                      _Step(
                          done: s.hasTeam,
                          label: 'Created at least one team'),
                      _Step(
                          done: s.hasMembers,
                          label: 'Invited members'),
                      _Step(
                          done: s.hasSchedule,
                          label: 'Set up an on-call schedule'),
                      _Step(
                          done: s.hasPolicy,
                          label: 'Created an escalation policy'),
                      _Step(
                          done: s.hasFirstAlert,
                          label: 'Received first alert'),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Step extends StatelessWidget {
  final bool done;
  final String label;
  const _Step({required this.done, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? AtlasColors.success : AtlasColors.textSubtle,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: done
                    ? AtlasColors.textPrimary
                    : AtlasColors.textSecondary,
                fontWeight: done ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingState {
  final bool hasTeam;
  final bool hasMembers;
  final bool hasSchedule;
  final bool hasPolicy;
  final bool hasFirstAlert;

  _OnboardingState({
    required this.hasTeam,
    required this.hasMembers,
    required this.hasSchedule,
    required this.hasPolicy,
    required this.hasFirstAlert,
  });

  int get completedCount =>
      [hasTeam, hasMembers, hasSchedule, hasPolicy, hasFirstAlert]
          .where((b) => b)
          .length;

  bool get isComplete => completedCount == 5;
}

Future<_OnboardingState> _detect(String orgId) async {
  final db = FirebaseFirestore.instance;

  final teamsFuture = CustomerPagersService.instance.getTeams(orgId);
  final membersFuture = db
      .collection('organizations')
      .doc(orgId)
      .collection('members')
      .limit(1)
      .get();
  final firstIncidentFuture = db
      .collection('inbound_emails')
      .where('orgId', isEqualTo: orgId)
      .limit(1)
      .get();

  final results = await Future.wait([
    teamsFuture,
    membersFuture,
    firstIncidentFuture,
  ]);

  final teams = results[0] as List;
  final members = results[1] as QuerySnapshot;
  final firstIncident = results[2] as QuerySnapshot;

  final hasTeam = teams.isNotEmpty;
  final hasMembers = members.docs.isNotEmpty;
  final hasFirstAlert = firstIncident.docs.isNotEmpty;

  bool hasSchedule = false;
  bool hasPolicy = false;
  if (hasTeam) {
    final schedules =
        await CustomerPagersService.instance.getSchedulesForOrg(orgId: orgId, limit: 1);
    hasSchedule = schedules.isNotEmpty;
    final policies =
        await CustomerPagersService.instance.getPoliciesForOrg(orgId);
    hasPolicy = policies.isNotEmpty;
  }

  return _OnboardingState(
    hasTeam: hasTeam,
    hasMembers: hasMembers,
    hasSchedule: hasSchedule,
    hasPolicy: hasPolicy,
    hasFirstAlert: hasFirstAlert,
  );
}

// ───────────────────────────────────────────────────────────────────────
// Helpers (cloned from customer_detail_screen.dart for cleanliness)
// ───────────────────────────────────────────────────────────────────────

Widget _row(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              color: AtlasColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AtlasColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _piiRow(String label, Widget child) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              color: AtlasColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

String _relative(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d, yyyy').format(when);
}
