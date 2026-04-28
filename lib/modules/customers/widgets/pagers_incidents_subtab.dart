import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/models/customer_incident_model.dart';
import '../../../core/services/customer_incident_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../utils/routes.dart';

class PagersIncidentsSubTab extends StatelessWidget {
  final String orgId;
  const PagersIncidentsSubTab({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CustomerIncident>>(
      stream: CustomerIncidentService.instance.watchForOrg(orgId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return _Error(message: snap.error.toString());
        }
        final incidents = snap.data ?? const [];
        if (incidents.isEmpty) {
          return const _Empty();
        }
        return _Table(incidents: incidents);
      },
    );
  }
}

class _Table extends StatelessWidget {
  final List<CustomerIncident> incidents;
  const _Table({required this.incidents});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      child: Column(
        children: [
          const _HeaderRow(),
          ...incidents.map((i) => _Row(incident: i)),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        color: AtlasColors.tableHeaderBg,
        border: Border(
          bottom: BorderSide(color: AtlasColors.tableBorder),
        ),
      ),
      child: Row(
        children: const [
          SizedBox(width: 90, child: _HeaderCell('ID')),
          Expanded(flex: 4, child: _HeaderCell('Title')),
          SizedBox(width: 70, child: _HeaderCell('Priority')),
          SizedBox(width: 90, child: _HeaderCell('Status')),
          SizedBox(width: 130, child: _HeaderCell('Assignee')),
          SizedBox(width: 80, child: _HeaderCell('MTTA')),
          SizedBox(width: 80, child: _HeaderCell('MTTR')),
          SizedBox(width: 110, child: _HeaderCell('Created')),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);
  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AtlasColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final CustomerIncident incident;
  const _Row({required this.incident});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(
        AtlasRoutes.customerIncidentDetail,
        arguments: incident.id,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AtlasColors.cardBorder)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                incident.incidentNumber.isNotEmpty
                    ? incident.incidentNumber
                    : incident.id,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AtlasColors.accent,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.title.isNotEmpty ? incident.title : '—',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AtlasColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (incident.teamName.isNotEmpty)
                    Text(
                      incident.teamName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AtlasColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 70,
              child: _PriorityPill(priority: incident.priority),
            ),
            SizedBox(
              width: 90,
              child: _StatusPill(status: incident.status),
            ),
            SizedBox(
              width: 130,
              child: Text(
                incident.assignedName ?? '—',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                _formatDuration(incident.mttaSeconds),
                style: const TextStyle(
                  fontSize: 12,
                  color: AtlasColors.textSecondary,
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                _formatDuration(incident.mttrSeconds),
                style: const TextStyle(
                  fontSize: 12,
                  color: AtlasColors.textSecondary,
                ),
              ),
            ),
            SizedBox(
              width: 110,
              child: Text(
                _formatRelative(incident.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AtlasColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  final String? priority;
  const _PriorityPill({required this.priority});

  @override
  Widget build(BuildContext context) {
    if (priority == null || priority!.isEmpty) {
      return const Text('—',
          style: TextStyle(fontSize: 12, color: AtlasColors.textMuted));
    }
    final p = priority!.toUpperCase();
    final color = switch (p) {
      'P1' => AtlasColors.danger,
      'P2' => AtlasColors.warning,
      'P3' => AtlasColors.info,
      _ => AtlasColors.textMuted,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: _Pill(label: p, color: color),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final (color, label) = switch (s) {
      'open' => (AtlasColors.warning, 'Open'),
      'ack' => (AtlasColors.info, 'Acked'),
      'acknowledged' => (AtlasColors.info, 'Acked'),
      'resolved' => (AtlasColors.success, 'Resolved'),
      _ => (AtlasColors.textMuted, status),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: _Pill(label: label, color: color),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AtlasRadius.round),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

String _formatDuration(int? seconds) {
  if (seconds == null) return '—';
  if (seconds < 60) return '${seconds}s';
  if (seconds < 3600) return '${(seconds / 60).round()}m';
  if (seconds < 86400) {
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).round();
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
  return '${(seconds / 86400).round()}d';
}

String _formatRelative(DateTime? when) {
  if (when == null) return '—';
  final now = DateTime.now();
  final diff = now.difference(when);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(when);
}

class _Empty extends StatelessWidget {
  const _Empty();
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
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 28, color: AtlasColors.textMuted),
          SizedBox(height: 8),
          Text(
            'No incidents in the last 30 days.',
            style: AtlasText.smallMuted,
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  const _Error({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AtlasColors.dangerSoft,
        border: Border.all(color: AtlasColors.danger),
        borderRadius: BorderRadius.circular(AtlasRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 18, color: AtlasColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Failed to load incidents: $message',
              style: const TextStyle(
                color: AtlasColors.danger,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
