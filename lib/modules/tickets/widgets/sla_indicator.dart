import 'package:flutter/material.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../theme/atlas_colors.dart';

/// Response-time SLA thresholds (by priority). If a ticket is open AND has
/// not received a first response within these windows, we flag it.
class SlaThresholds {
  SlaThresholds._();
  static const urgent = Duration(hours: 1);
  static const high = Duration(hours: 4);
  static const normal = Duration(hours: 24);
  static const low = Duration(hours: 72);

  static Duration forPriority(TicketPriority p) {
    switch (p) {
      case TicketPriority.urgent:
        return urgent;
      case TicketPriority.high:
        return high;
      case TicketPriority.normal:
        return normal;
      case TicketPriority.low:
        return low;
    }
  }
}

enum SlaState { onTrack, warning, breached, met }

/// Evaluates SLA state for a ticket based on its priority, status, and
/// firstResponseAt timestamp.
SlaState evaluateSla(SupportTicket ticket) {
  if (ticket.status.isClosed) return SlaState.met;
  final threshold = SlaThresholds.forPriority(ticket.priority);
  final age = DateTime.now().difference(ticket.createdAt);
  if (age >= threshold) return SlaState.breached;
  if (age >= threshold * 0.75) return SlaState.warning;
  return SlaState.onTrack;
}

/// Small inline badge showing SLA state. Use in ticket queues and detail.
class SlaBadge extends StatelessWidget {
  final SupportTicket ticket;
  final bool compact;
  const SlaBadge({super.key, required this.ticket, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final state = evaluateSla(ticket);
    if (state == SlaState.met || state == SlaState.onTrack) {
      return const SizedBox.shrink();
    }

    final isBreach = state == SlaState.breached;
    final color = isBreach ? AtlasColors.danger : AtlasColors.warning;
    final bg = isBreach ? AtlasColors.dangerSoft : AtlasColors.warningSoft;
    final label = isBreach ? 'SLA BREACH' : 'SLA WARN';

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AtlasRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isBreach ? Icons.error_outline : Icons.warning_amber_rounded,
              size: compact ? 10 : 11, color: color),
          SizedBox(width: compact ? 3 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 9 : 9.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
