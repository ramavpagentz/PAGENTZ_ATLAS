import 'package:flutter/material.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../theme/atlas_colors.dart';

class StatusPill extends StatelessWidget {
  final TicketStatus status;
  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      TicketStatus.newTicket => (AtlasColors.info, AtlasColors.infoSoft),
      TicketStatus.open => (AtlasColors.warning, AtlasColors.warningSoft),
      TicketStatus.pendingCustomer => (
          Colors.purple.shade700,
          Colors.purple.shade50
        ),
      TicketStatus.resolved => (AtlasColors.success, AtlasColors.successSoft),
      TicketStatus.closed => (
          AtlasColors.pillNeutralText,
          AtlasColors.pillNeutral
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(AtlasRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: colors.$1,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colors.$1,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class PriorityPill extends StatelessWidget {
  final TicketPriority priority;
  const PriorityPill({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final colors = switch (priority) {
      TicketPriority.urgent => (AtlasColors.danger, AtlasColors.dangerSoft),
      TicketPriority.high => (
          Colors.orange.shade800,
          Colors.orange.shade50
        ),
      TicketPriority.normal => (AtlasColors.info, AtlasColors.infoSoft),
      TicketPriority.low => (
          AtlasColors.pillNeutralText,
          AtlasColors.pillNeutral
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(AtlasRadius.round),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colors.$1,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
