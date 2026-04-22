import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/activity_log_model.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../theme/atlas_colors.dart';

/// Reverse-chronological customer activity timeline. Shown inside the
/// Customer Detail screen.
class ActivityTimelineWidget extends StatelessWidget {
  final String orgId;
  const ActivityTimelineWidget({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityLog>>(
      stream: ActivityLogService.instance.watchOrgActivity(orgId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                'Could not load activity: ${snap.error}',
                style: const TextStyle(color: AtlasColors.danger, fontSize: 13),
              ),
            ),
          );
        }
        final logs = snap.data ?? const [];
        if (logs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text(
                'No activity recorded for this organization yet.',
                style: TextStyle(color: AtlasColors.textMuted, fontSize: 13),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < logs.length; i++)
              _TimelineRow(
                log: logs[i],
                isLast: i == logs.length - 1,
              ),
          ],
        );
      },
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final ActivityLog log;
  final bool isLast;
  const _TimelineRow({required this.log, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, HH:mm');
    final isStaffAction = log.actorType == 'staff_impersonating';

    final dotColor = switch (log.category) {
      'security' => AtlasColors.danger,
      'config' => AtlasColors.warning,
      'operations' => AtlasColors.info,
      _ => AtlasColors.accent,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AtlasColors.cardBg, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AtlasColors.cardBorder),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.eventLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AtlasColors.textPrimary,
                          ),
                        ),
                      ),
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
                  const SizedBox(height: 2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      _MetaChip(label: log.eventType),
                      if (log.module.isNotEmpty)
                        _MetaChip(label: log.module, soft: true),
                      Text(
                        '· by ${log.actorDisplay}',
                        style: const TextStyle(
                          color: AtlasColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (isStaffAction)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AtlasColors.dangerSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'STAFF',
                            style: TextStyle(
                              color: AtlasColors.danger,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final bool soft;
  const _MetaChip({required this.label, this.soft = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: soft ? const Color(0xFFF1F5F9) : AtlasColors.accentSoft,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: soft ? AtlasColors.textSecondary : AtlasColors.accentHover,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
