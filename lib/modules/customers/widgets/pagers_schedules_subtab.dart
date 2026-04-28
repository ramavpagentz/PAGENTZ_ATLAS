import 'package:flutter/material.dart';

import '../../../core/models/customer_org_model.dart';
import '../../../core/models/customer_pagers_models.dart';
import '../../../core/services/customer_pagers_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../utils/staff_redirect.dart';
import 'snapshot_redirect_card.dart';

/// Schedules sub-tab — snapshot pattern. Surfaces the most recent on-call
/// rows as a "current state" preview; full calendar / week-month / past
/// schedules live in the customer app.
class PagersSchedulesSubTab extends StatelessWidget {
  final CustomerOrg org;
  const PagersSchedulesSubTab({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CustomerSchedule>>(
      future: CustomerPagersService.instance.getSchedulesForOrg(orgId: org.id),
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
        final schedules = snap.data ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (schedules.isEmpty)
              const _EmptyBox(
                  message: 'No on-call schedules configured for this org.')
            else
              _ScheduleList(schedules: schedules),
            const SizedBox(height: AtlasSpace.lg),
            SnapshotRedirectCard(
              title: 'View the full on-call calendar',
              subtitle:
                  'Atlas only shows the most recent rotations. The week / month grid, history, and rotation editor live in the customer app.',
              buttonLabel: 'Open Schedules in customer view',
              onTap: () => StaffRedirect.open(
                orgId: org.id,
                orgName: org.name,
                subPath: '/scheduleScreen',
                auditAction: 'OPENED_CUSTOMER_SCHEDULES',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScheduleList extends StatelessWidget {
  final List<CustomerSchedule> schedules;
  const _ScheduleList({required this.schedules});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      child: Column(
        children: schedules
            .map((s) => _Row(schedule: s, isLast: s == schedules.last))
            .toList(),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final CustomerSchedule schedule;
  final bool isLast;
  const _Row({required this.schedule, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AtlasColors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AtlasColors.accentSoft,
              borderRadius: BorderRadius.circular(AtlasRadius.md),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.schedule,
                size: 16, color: AtlasColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.scheduleName.isNotEmpty
                      ? schedule.scheduleName
                      : (schedule.teamName.isNotEmpty
                          ? '${schedule.teamName} on-call'
                          : 'On-call rotation'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AtlasColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(schedule),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AtlasColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (schedule.primaryNames.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AtlasColors.successSoft,
                borderRadius: BorderRadius.circular(AtlasRadius.round),
              ),
              child: Text(
                schedule.primaryNames.join(', '),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AtlasColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _subtitle(CustomerSchedule s) {
    final parts = <String>[];
    if (s.teamName.isNotEmpty) parts.add(s.teamName);
    if (s.date.isNotEmpty) parts.add(s.date);
    if (s.startTime.isNotEmpty && s.endTime.isNotEmpty) {
      parts.add('${s.startTime} – ${s.endTime}');
    }
    if (s.rotation.isNotEmpty) parts.add(s.rotation);
    return parts.join(' · ');
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
          const Icon(Icons.event_busy,
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
        'Failed to load schedules: $message',
        style: const TextStyle(color: AtlasColors.danger, fontSize: 12),
      ),
    );
  }
}
