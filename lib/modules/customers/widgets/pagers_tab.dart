import 'package:flutter/material.dart';

import '../../../core/models/customer_org_model.dart';
import '../../../theme/atlas_colors.dart';
import 'pagers_channels_subtab.dart';
import 'pagers_incidents_subtab.dart';
import 'pagers_notification_health_subtab.dart';
import 'pagers_policies_subtab.dart';
import 'pagers_schedules_subtab.dart';
import 'pagers_teams_subtab.dart';
import 'pagers_webhooks_subtab.dart';

/// Pagers tab — the "big one" per the Customer 360 spec. Hosts seven
/// sub-tabs, four of which are "full" Atlas views (Incidents, Notification
/// Health, Channels, Webhooks) and three of which are "snapshot + redirect"
/// to the customer app via staffMode (Teams, Schedules, Policies).
///
/// Sub-tab content is filled in the Phase 1.x stages — this file owns the
/// frame and the strip.
class PagersTab extends StatefulWidget {
  final CustomerOrg org;
  const PagersTab({super.key, required this.org});

  @override
  State<PagersTab> createState() => _PagersTabState();
}

enum PagersSubTab {
  incidents('Incidents'),
  notificationHealth('Notification health'),
  channels('Channels'),
  webhooks('Webhooks'),
  schedules('Schedules'),
  policies('Policies'),
  teams('Teams');

  final String label;
  const PagersSubTab(this.label);
}

class _PagersTabState extends State<PagersTab> {
  PagersSubTab _sub = PagersSubTab.incidents;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SubTabStrip(
          selected: _sub,
          onSelect: (s) => setState(() => _sub = s),
        ),
        const SizedBox(height: AtlasSpace.lg),
        _content(),
      ],
    );
  }

  Widget _content() {
    switch (_sub) {
      case PagersSubTab.incidents:
        return PagersIncidentsSubTab(orgId: widget.org.id);
      case PagersSubTab.notificationHealth:
        return PagersNotificationHealthSubTab(orgId: widget.org.id);
      case PagersSubTab.channels:
        return PagersChannelsSubTab(orgId: widget.org.id);
      case PagersSubTab.webhooks:
        return PagersWebhooksSubTab(orgId: widget.org.id);
      case PagersSubTab.schedules:
        return PagersSchedulesSubTab(org: widget.org);
      case PagersSubTab.policies:
        return PagersPoliciesSubTab(org: widget.org);
      case PagersSubTab.teams:
        return PagersTeamsSubTab(org: widget.org);
    }
  }
}

class _SubTabStrip extends StatelessWidget {
  final PagersSubTab selected;
  final ValueChanged<PagersSubTab> onSelect;
  const _SubTabStrip({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AtlasColors.pillNeutral,
        borderRadius: BorderRadius.circular(AtlasRadius.md),
      ),
      child: Wrap(
        spacing: 4,
        children: PagersSubTab.values.map((s) {
          final isSel = s == selected;
          return _SubTabPill(
            label: s.label,
            selected: isSel,
            onTap: () => onSelect(s),
          );
        }).toList(),
      ),
    );
  }
}

class _SubTabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SubTabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AtlasRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AtlasColors.cardBg : Colors.transparent,
          borderRadius: BorderRadius.circular(AtlasRadius.sm),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AtlasColors.textPrimary : AtlasColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

