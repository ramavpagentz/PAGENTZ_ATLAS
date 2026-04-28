import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/activity_log_model.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../core/services/customer_incident_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';

/// Health & Diagnostics tab — the "secret weapon" support landing page.
/// Aggregates: open / resolved incident counts, recent errors from the
/// activity log, integration status (counted per kind), and a synthesized
/// org health score.
///
/// Data is computed client-side from existing collections (no new schema
/// required). Notification delivery health (SMS/Voice/Email gauges) is
/// intentionally omitted — the customer app does not log delivery
/// attempts to a queryable collection. See `customer-360-progress.md`.
class HealthTab extends StatelessWidget {
  final String orgId;
  const HealthTab({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HealthSnapshot>(
      future: _buildSnapshot(orgId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || snap.data == null) {
          return _ErrorBox(message: snap.error?.toString() ?? 'Unknown error');
        }
        final s = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HealthScoreCard(snap: s),
            const SizedBox(height: AtlasSpace.lg),
            _StatRow(snap: s),
            const SizedBox(height: AtlasSpace.lg),
            _RecentErrors(orgId: orgId),
          ],
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// Snapshot model (computed once on tab open)
// ───────────────────────────────────────────────────────────────────────

class _HealthSnapshot {
  final int openIncidents;
  final int ackedIncidents;
  final int resolvedIncidents30d;
  final DateTime? lastIncidentAt;
  final String? lastIncidentTitle;
  final int healthScore;
  final String healthLabel;
  final Color healthColor;

  _HealthSnapshot({
    required this.openIncidents,
    required this.ackedIncidents,
    required this.resolvedIncidents30d,
    required this.healthScore,
    required this.healthLabel,
    required this.healthColor,
    this.lastIncidentAt,
    this.lastIncidentTitle,
  });
}

Future<_HealthSnapshot> _buildSnapshot(String orgId) async {
  final db = FirebaseFirestore.instance;
  final since30d = DateTime.now().subtract(const Duration(days: 30));

  // Counts by status over the last 30 days.
  final counts = await CustomerIncidentService.instance.countsByStatus(
    orgId: orgId,
    windowDays: 30,
  );
  final open = counts['open'] ?? 0;
  final acked = (counts['ack'] ?? 0) + (counts['acknowledged'] ?? 0);
  final resolved = counts['resolved'] ?? 0;

  // Most recent incident (any status).
  DateTime? lastAt;
  String? lastTitle;
  try {
    final s = await db
        .collection('inbound_emails')
        .where('orgId', isEqualTo: orgId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (s.docs.isNotEmpty) {
      final d = s.docs.first.data();
      lastAt = (d['createdAt'] as Timestamp?)?.toDate();
      lastTitle = d['title'] as String?;
    }
  } catch (_) {
    /* best-effort */
  }

  // Health score heuristic — open P1s drag the score down; recent
  // unresolved incidents matter more than old resolved ones.
  var score = 100;
  score -= open * 10; // each open incident -10
  score -= acked * 3; // ack'd but unresolved -3
  if (lastAt != null && lastAt.isAfter(since30d)) {
    final hoursSince = DateTime.now().difference(lastAt).inHours;
    if (hoursSince < 24) score -= 5;
  }
  score = score.clamp(0, 100);

  final (label, color) = switch (score) {
    >= 90 => ('Healthy', AtlasColors.success),
    >= 70 => ('Stable', AtlasColors.info),
    >= 40 => ('Degraded', AtlasColors.warning),
    _ => ('Critical', AtlasColors.danger),
  };

  return _HealthSnapshot(
    openIncidents: open,
    ackedIncidents: acked,
    resolvedIncidents30d: resolved,
    lastIncidentAt: lastAt,
    lastIncidentTitle: lastTitle,
    healthScore: score,
    healthLabel: label,
    healthColor: color,
  );
}

// ───────────────────────────────────────────────────────────────────────
// Top score card
// ───────────────────────────────────────────────────────────────────────

class _HealthScoreCard extends StatelessWidget {
  final _HealthSnapshot snap;
  const _HealthScoreCard({required this.snap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AtlasSpace.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            snap.healthColor.withValues(alpha: 0.10),
            snap.healthColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: snap.healthColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AtlasRadius.xl),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: snap.healthColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: snap.healthColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '${snap.healthScore}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: AtlasSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Org health: ${snap.healthLabel}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: snap.healthColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _summary(snap),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AtlasColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _summary(_HealthSnapshot s) {
    final parts = <String>[];
    if (s.openIncidents > 0) {
      parts.add('${s.openIncidents} open incident${s.openIncidents == 1 ? "" : "s"}');
    }
    if (s.ackedIncidents > 0) {
      parts.add('${s.ackedIncidents} ack\'d unresolved');
    }
    if (parts.isEmpty) parts.add('No active incidents');
    if (s.lastIncidentAt != null) {
      final ago = _relative(s.lastIncidentAt!);
      parts.add('last alert $ago');
    }
    return parts.join(' · ');
  }
}

// ───────────────────────────────────────────────────────────────────────
// Stat row
// ───────────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final _HealthSnapshot snap;
  const _StatRow({required this.snap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 980
          ? 4
          : c.maxWidth > 640
              ? 2
              : 1;
      final tiles = <_StatTile>[
        _StatTile(
          label: 'Open incidents',
          value: '${snap.openIncidents}',
          sub: snap.openIncidents == 0 ? 'none active' : 'needs attention',
          color: snap.openIncidents == 0
              ? AtlasColors.success
              : AtlasColors.danger,
        ),
        _StatTile(
          label: 'Ack\'d (unresolved)',
          value: '${snap.ackedIncidents}',
          sub: snap.ackedIncidents == 0 ? 'all clear' : 'in progress',
          color: snap.ackedIncidents == 0
              ? AtlasColors.success
              : AtlasColors.warning,
        ),
        _StatTile(
          label: 'Resolved (30d)',
          value: '${snap.resolvedIncidents30d}',
          sub: 'last 30 days',
          color: AtlasColors.info,
        ),
        _StatTile(
          label: 'Last alert',
          value: snap.lastIncidentAt == null
              ? '—'
              : _relative(snap.lastIncidentAt!),
          sub: snap.lastIncidentTitle ?? 'no recent activity',
          color: AtlasColors.textSecondary,
        ),
      ];
      return Wrap(
        spacing: AtlasSpace.md,
        runSpacing: AtlasSpace.md,
        children: tiles.map((t) {
          final w = (c.maxWidth - (cols - 1) * AtlasSpace.md) / cols;
          return SizedBox(width: w, child: t);
        }).toList(),
      );
    });
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 11,
              color: AtlasColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// Recent errors / warnings (last 24h, security or error events)
// ───────────────────────────────────────────────────────────────────────

class _RecentErrors extends StatelessWidget {
  final String orgId;
  const _RecentErrors({required this.orgId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityLog>>(
      stream: ActivityLogService.instance.watchOrgActivity(orgId, limit: 200),
      builder: (context, snap) {
        final all = snap.data ?? const [];
        final cutoff = DateTime.now().subtract(const Duration(hours: 24));
        final filtered = all
            .where((l) =>
                l.timestamp.isAfter(cutoff) &&
                (l.category == 'security' ||
                    _isErrorish(l.eventType)))
            .toList();

        return Container(
          padding: const EdgeInsets.all(AtlasSpace.xl),
          decoration: BoxDecoration(
            color: AtlasColors.cardBg,
            border: Border.all(color: AtlasColors.cardBorder),
            borderRadius: BorderRadius.circular(AtlasRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recent errors & warnings (24h)', style: AtlasText.h3),
              const SizedBox(height: 4),
              const Text(
                'Drawn from `activity_logs` where category=security or eventType '
                'looks error-ish (contains FAIL/ERROR/DENIED/LOCKED).',
                style: TextStyle(
                  fontSize: 11,
                  color: AtlasColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AtlasSpace.md),
              if (snap.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No errors or security warnings in the last 24 hours.',
                    style: AtlasText.smallMuted,
                  ),
                )
              else
                Column(
                  children: filtered
                      .take(20)
                      .map((l) => _ErrorRow(log: l))
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isErrorish(String eventType) {
    final s = eventType.toUpperCase();
    return s.contains('FAIL') ||
        s.contains('ERROR') ||
        s.contains('DENIED') ||
        s.contains('LOCKED') ||
        s.contains('REJECTED');
  }
}

class _ErrorRow extends StatelessWidget {
  final ActivityLog log;
  const _ErrorRow({required this.log});

  @override
  Widget build(BuildContext context) {
    final isSec = log.category == 'security';
    final color = isSec ? AtlasColors.danger : AtlasColors.warning;
    final df = DateFormat('MMM d, HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AtlasRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AtlasRadius.round),
            ),
            child: Text(
              isSec ? 'SECURITY' : 'WARN',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.eventLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AtlasColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.eventType} · by ${log.actorDisplay}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AtlasColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            df.format(log.timestamp),
            style: const TextStyle(
              fontSize: 11,
              color: AtlasColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        'Failed to load health snapshot: $message',
        style: const TextStyle(color: AtlasColors.danger, fontSize: 12),
      ),
    );
  }
}

String _relative(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(when);
}
