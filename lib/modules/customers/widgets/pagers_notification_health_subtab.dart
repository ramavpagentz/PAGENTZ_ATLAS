import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/customer_incident_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';

/// Notification Health sub-tab — degraded version of the spec's gauges.
///
/// **What's measurable today:**
///   • Incidents created in the last 24h / 7d (from `inbound_emails`)
///   • Acked vs unacked counts (status field on incident)
///   • SMS sent to engineers (rows in `sms_incident_map` per incident)
///   • Incident creation timing histogram (last 24 buckets)
///
/// **What's NOT measurable today:**
///   • Postmark email delivery status (no webhook back to Firestore)
///   • Voice call disposition (no log written for each call attempt)
///   • Push notification delivery
///
/// Once the customer-app side adds a `notification_deliveries` collection
/// with one row per send + result, the per-channel SMS/Voice/Email gauges
/// from the spec become buildable. Until then this widget surfaces the
/// closest available signal and clearly labels the gap.
class PagersNotificationHealthSubTab extends StatelessWidget {
  final String orgId;
  const PagersNotificationHealthSubTab({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_NotifSnapshot>(
      future: _build(orgId),
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
            _GaugeRow(snap: s),
            const SizedBox(height: AtlasSpace.lg),
            _Histogram(buckets: s.incidentBuckets24h),
            const SizedBox(height: AtlasSpace.lg),
            _Caveat(),
          ],
        );
      },
    );
  }
}

class _NotifSnapshot {
  final int incidentsLast24h;
  final int incidentsLast7d;
  final int ackedLast24h;
  final int unackedLast24h;
  final int smsLast24h;
  final int smsLast7d;

  /// 24 buckets, oldest → newest, each value = incidents created in that hour.
  final List<int> incidentBuckets24h;

  _NotifSnapshot({
    required this.incidentsLast24h,
    required this.incidentsLast7d,
    required this.ackedLast24h,
    required this.unackedLast24h,
    required this.smsLast24h,
    required this.smsLast7d,
    required this.incidentBuckets24h,
  });
}

Future<_NotifSnapshot> _build(String orgId) async {
  final db = FirebaseFirestore.instance;
  final now = DateTime.now();
  final since24h = now.subtract(const Duration(hours: 24));
  final since7d = now.subtract(const Duration(days: 7));

  final incidents24Future = db
      .collection('inbound_emails')
      .where('orgId', isEqualTo: orgId)
      .where('createdAt', isGreaterThan: Timestamp.fromDate(since24h))
      .orderBy('createdAt', descending: true)
      .get();
  final incidents7dCountFuture = CustomerIncidentService.instance
      .countsByStatus(orgId: orgId, windowDays: 7);

  // sms_incident_map is org-agnostic; we filter by `incidentId` after pulling
  // a window of recent rows. To stay performant, we cap at 200 most-recent
  // rows since 7d ago and intersect with this org's incidents in-memory.
  final smsRecentFuture = db
      .collection('sms_incident_map')
      .where('sentAt', isGreaterThan: Timestamp.fromDate(since7d))
      .orderBy('sentAt', descending: true)
      .limit(200)
      .get();

  final results = await Future.wait<dynamic>([
    incidents24Future,
    incidents7dCountFuture,
    smsRecentFuture,
  ]);
  final incs24 = results[0] as QuerySnapshot;
  final counts7d = results[1] as Map<String, int>;
  final sms = results[2] as QuerySnapshot;

  // Incident bucket histogram (24 hourly buckets).
  final buckets = List<int>.filled(24, 0);
  var acked = 0;
  var unacked = 0;
  for (final d in incs24.docs) {
    final data = d.data() as Map<String, dynamic>;
    final t = (data['createdAt'] as Timestamp?)?.toDate();
    if (t == null) continue;
    final hoursAgo = now.difference(t).inHours;
    final idx = 23 - hoursAgo.clamp(0, 23);
    buckets[idx] += 1;
    final status = (data['status'] as String?) ?? 'open';
    if (status == 'open') {
      unacked += 1;
    } else {
      acked += 1;
    }
  }

  // SMS rows scoped to this org by intersecting incidentId with this org's
  // incidents from the same query window.
  final orgIncidentIds = incs24.docs.map((d) => d.id).toSet();
  // Also consider incidents in 7d window for smsLast7d. Quick fetch: read
  // the 7d incident ids in a separate light query.
  final incs7dDocs = await db
      .collection('inbound_emails')
      .where('orgId', isEqualTo: orgId)
      .where('createdAt', isGreaterThan: Timestamp.fromDate(since7d))
      .orderBy('createdAt', descending: true)
      .get();
  final orgIncident7dIds = incs7dDocs.docs.map((d) => d.id).toSet();

  var smsLast24h = 0;
  var smsLast7d = 0;
  for (final d in sms.docs) {
    final data = d.data() as Map<String, dynamic>;
    final id = (data['incidentId'] as String?) ?? '';
    final t = (data['sentAt'] as Timestamp?)?.toDate();
    if (t == null || id.isEmpty) continue;
    if (orgIncident7dIds.contains(id)) {
      smsLast7d += 1;
      if (now.difference(t).inHours < 24 && orgIncidentIds.contains(id)) {
        smsLast24h += 1;
      }
    }
  }

  return _NotifSnapshot(
    incidentsLast24h: incs24.docs.length,
    incidentsLast7d:
        (counts7d['open'] ?? 0) + (counts7d['ack'] ?? 0) + (counts7d['acknowledged'] ?? 0) + (counts7d['resolved'] ?? 0),
    ackedLast24h: acked,
    unackedLast24h: unacked,
    smsLast24h: smsLast24h,
    smsLast7d: smsLast7d,
    incidentBuckets24h: buckets,
  );
}

class _GaugeRow extends StatelessWidget {
  final _NotifSnapshot snap;
  const _GaugeRow({required this.snap});

  @override
  Widget build(BuildContext context) {
    final ack = snap.ackedLast24h + snap.unackedLast24h == 0
        ? 100
        : ((snap.ackedLast24h * 100) /
                (snap.ackedLast24h + snap.unackedLast24h))
            .round();

    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 980 ? 4 : (c.maxWidth > 640 ? 2 : 1);
      final tiles = <Widget>[
        _Gauge(
          label: 'Incidents · 24h',
          value: '${snap.incidentsLast24h}',
          sub: '${snap.unackedLast24h} unacked · ${snap.ackedLast24h} acked',
          fillPct: snap.incidentsLast24h == 0 ? 0 : 100,
          color: snap.unackedLast24h == 0
              ? AtlasColors.success
              : AtlasColors.warning,
        ),
        _Gauge(
          label: 'Ack rate · 24h',
          value: '$ack%',
          sub:
              snap.ackedLast24h + snap.unackedLast24h == 0 ? 'no incidents' : 'of acted-on incidents',
          fillPct: ack,
          color: ack >= 90
              ? AtlasColors.success
              : (ack >= 50 ? AtlasColors.warning : AtlasColors.danger),
        ),
        _Gauge(
          label: 'SMS sent · 24h',
          value: '${snap.smsLast24h}',
          sub: 'to engineers via Vonage',
          fillPct: snap.smsLast24h == 0 ? 0 : 100,
          color: AtlasColors.info,
        ),
        _Gauge(
          label: 'SMS sent · 7d',
          value: '${snap.smsLast7d}',
          sub: 'across all incidents',
          fillPct: snap.smsLast7d == 0 ? 0 : 100,
          color: AtlasColors.info,
        ),
      ];
      return Wrap(
        spacing: AtlasSpace.md,
        runSpacing: AtlasSpace.md,
        children: tiles
            .map((t) => SizedBox(
                  width: (c.maxWidth - (cols - 1) * AtlasSpace.md) / cols,
                  child: t,
                ))
            .toList(),
      );
    });
  }
}

class _Gauge extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final int fillPct;
  final Color color;
  const _Gauge({
    required this.label,
    required this.value,
    required this.sub,
    required this.fillPct,
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
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
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
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (fillPct / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AtlasColors.tableHeaderBg,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Histogram extends StatelessWidget {
  final List<int> buckets;
  const _Histogram({required this.buckets});
  @override
  Widget build(BuildContext context) {
    final maxV = buckets.fold<int>(0, (a, b) => a > b ? a : b);
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
          const Text('Incidents by hour (last 24h)', style: AtlasText.h3),
          const SizedBox(height: 4),
          const Text(
            'Each bar is one hour. Tall bars = bursty incident creation.',
            style: TextStyle(
              fontSize: 11.5,
              color: AtlasColors.textMuted,
            ),
          ),
          const SizedBox(height: AtlasSpace.md),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final v in buckets)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: FractionallySizedBox(
                        heightFactor:
                            maxV == 0 ? 0.04 : (v / maxV).clamp(0.04, 1.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: v == 0
                                ? AtlasColors.cardBorder
                                : (v > maxV / 2
                                    ? AtlasColors.warning
                                    : AtlasColors.info),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Text('24h ago',
                  style:
                      TextStyle(fontSize: 10, color: AtlasColors.textMuted)),
              Spacer(),
              Text('now',
                  style:
                      TextStyle(fontSize: 10, color: AtlasColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Caveat extends StatelessWidget {
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
              'Per-channel delivery gauges (SMS / Voice / Email succeeded vs '
              'failed) require a `notification_deliveries` collection on the '
              'customer-app side. Until that exists, this view shows incident '
              'volume + SMS-sent counts as the closest available signal. '
              'Postmark + Vonage do not currently webhook delivery results back.',
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
        'Failed to load notification health: $message',
        style: const TextStyle(color: AtlasColors.danger, fontSize: 12),
      ),
    );
  }
}
