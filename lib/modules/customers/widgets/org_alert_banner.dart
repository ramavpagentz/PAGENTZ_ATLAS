import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/customer_incident_model.dart';
import '../../../core/services/customer_incident_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../utils/routes.dart';

/// Sticky alert banner shown above the org-detail page header when this
/// org has an active P1 incident or an unacked open incident over 10
/// minutes old. Tapping the banner deep-links into the incident detail.
///
/// Inert (renders nothing) when the org is healthy. Streams from the
/// incidents service so it auto-clears the moment the customer acks/
/// resolves.
class OrgAlertBanner extends StatelessWidget {
  final String orgId;
  const OrgAlertBanner({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CustomerIncident>>(
      stream: CustomerIncidentService.instance.watchForOrg(orgId, limit: 25),
      builder: (context, snap) {
        final all = snap.data ?? const <CustomerIncident>[];
        final active = all.where((i) => i.isOpen).toList();
        if (active.isEmpty) return const SizedBox.shrink();

        // Pick worst signal: P1 open > P2 open > old unacked.
        final p1 = active.firstWhereOrNull(
          (i) => (i.priority ?? '').toUpperCase() == 'P1',
        );
        final p2 = active.firstWhereOrNull(
          (i) => (i.priority ?? '').toUpperCase() == 'P2',
        );
        final oldestUnacked = active
            .where((i) =>
                i.acknowledgedAt == null &&
                i.createdAt != null &&
                DateTime.now().difference(i.createdAt!).inMinutes >= 10)
            .toList()
          ..sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
        final stale = oldestUnacked.isNotEmpty ? oldestUnacked.first : null;

        final tiles = <Widget>[];
        if (p1 != null) {
          tiles.add(_BannerTile(
            severity: _BannerSeverity.critical,
            title: 'Active P1 incident: ${p1.title.isNotEmpty ? p1.title : "(no title)"}',
            subtitle: _ageLabel(p1) +
                (p1.acknowledgedAt == null ? ' · NOT acknowledged' : ''),
            onTap: () => Get.toNamed(
              AtlasRoutes.customerIncidentDetail,
              arguments: p1.id,
            ),
          ));
        } else if (p2 != null) {
          tiles.add(_BannerTile(
            severity: _BannerSeverity.warning,
            title: 'Active P2 incident: ${p2.title.isNotEmpty ? p2.title : "(no title)"}',
            subtitle: _ageLabel(p2),
            onTap: () => Get.toNamed(
              AtlasRoutes.customerIncidentDetail,
              arguments: p2.id,
            ),
          ));
        } else if (stale != null) {
          tiles.add(_BannerTile(
            severity: _BannerSeverity.warning,
            title:
                'Unacked open incident: ${stale.title.isNotEmpty ? stale.title : "(no title)"}',
            subtitle: 'Created ${_ageLabel(stale)}, no ack yet',
            onTap: () => Get.toNamed(
              AtlasRoutes.customerIncidentDetail,
              arguments: stale.id,
            ),
          ));
        } else {
          // Active incidents exist but none are urgent — show a soft note.
          tiles.add(_BannerTile(
            severity: _BannerSeverity.info,
            title: '${active.length} open incident${active.length == 1 ? "" : "s"}',
            subtitle: 'all acknowledged · monitoring',
            onTap: null,
          ));
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: tiles,
          ),
        );
      },
    );
  }

  String _ageLabel(CustomerIncident i) {
    if (i.createdAt == null) return 'open';
    final diff = DateTime.now().difference(i.createdAt!);
    if (diff.inMinutes < 60) return 'open ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'open ${diff.inHours}h';
    return 'open ${diff.inDays}d';
  }
}

enum _BannerSeverity { critical, warning, info }

class _BannerTile extends StatelessWidget {
  final _BannerSeverity severity;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _BannerTile({
    required this.severity,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, borderColor, iconData) = switch (severity) {
      _BannerSeverity.critical => (
          AtlasColors.dangerSoft,
          AtlasColors.danger,
          AtlasColors.danger,
          Icons.error_outline,
        ),
      _BannerSeverity.warning => (
          AtlasColors.warningSoft,
          AtlasColors.warning,
          AtlasColors.warning,
          Icons.warning_amber_outlined,
        ),
      _BannerSeverity.info => (
          AtlasColors.infoSoft,
          AtlasColors.info,
          AtlasColors.info,
          Icons.info_outline,
        ),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AtlasRadius.md),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(AtlasRadius.md),
          ),
          child: Row(
            children: [
              Icon(iconData, size: 18, color: fgColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: fgColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: fgColor.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, size: 18, color: fgColor),
            ],
          ),
        ),
      ),
    );
  }
}
