import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/models/customer_incident_model.dart';
import '../../../core/services/customer_incident_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../utils/routes.dart';
import '../../../widgets/app_shell.dart';

/// Drill-down view for a single customer incident. Reached from the Pagers
/// tab incidents list. Read-only — no ack / resolve / comment actions.
class CustomerIncidentDetailScreen extends StatefulWidget {
  const CustomerIncidentDetailScreen({super.key});

  @override
  State<CustomerIncidentDetailScreen> createState() =>
      _CustomerIncidentDetailScreenState();
}

class _CustomerIncidentDetailScreenState
    extends State<CustomerIncidentDetailScreen> {
  late final String? incidentId;
  CustomerIncident? _incident;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    incidentId = Get.arguments as String?;
    _load();
  }

  Future<void> _load() async {
    if (incidentId == null) {
      setState(() {
        _loading = false;
        _error = 'No incident id provided.';
      });
      return;
    }
    try {
      final inc = await CustomerIncidentService.instance.getById(incidentId!);
      if (!mounted) return;
      setState(() {
        _incident = inc;
        _loading = false;
        if (inc == null) _error = 'Incident not found.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AtlasRoutes.customerIncidentDetail,
      pageTitle: 'Incident detail',
      pageSubtitle: 'Read-only view of a customer incident.',
      child: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 36, color: AtlasColors.danger),
            const SizedBox(height: 8),
            Text(_error!, style: AtlasText.smallMuted),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Get.back<void>(),
              icon: const Icon(Icons.arrow_back, size: 14),
              label: const Text('Back'),
            ),
          ],
        ),
      );
    }
    final inc = _incident!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackLink(),
        const SizedBox(height: AtlasSpace.md),
        _HeaderCard(incident: inc),
        const SizedBox(height: AtlasSpace.lg),
        _DetailGrid(incident: inc),
        const SizedBox(height: AtlasSpace.lg),
        _NotesSection(incidentId: inc.id),
      ],
    );
  }
}

class _BackLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.back<void>(),
      borderRadius: BorderRadius.circular(AtlasRadius.sm),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: AtlasSpace.sm, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, size: 14, color: AtlasColors.textSecondary),
            SizedBox(width: 6),
            Text(
              'Back to customer',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AtlasColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final CustomerIncident incident;
  const _HeaderCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AtlasSpace.xl),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
        boxShadow: AtlasElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (incident.incidentNumber.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    incident.incidentNumber,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AtlasColors.accent,
                    ),
                  ),
                ),
              if (incident.priority != null)
                _MetaPill(
                  label: incident.priority!,
                  color: switch (incident.priority!.toUpperCase()) {
                    'P1' => AtlasColors.danger,
                    'P2' => AtlasColors.warning,
                    'P3' => AtlasColors.info,
                    _ => AtlasColors.textMuted,
                  },
                ),
              const SizedBox(width: 8),
              _MetaPill(
                label: incident.status.toUpperCase(),
                color: switch (incident.status.toLowerCase()) {
                  'open' => AtlasColors.warning,
                  'ack' => AtlasColors.info,
                  'acknowledged' => AtlasColors.info,
                  'resolved' => AtlasColors.success,
                  _ => AtlasColors.textMuted,
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            incident.title.isNotEmpty ? incident.title : '(no title)',
            style: AtlasText.h2,
          ),
          if (incident.teamName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Team · ${incident.teamName}',
              style: AtlasText.smallMuted,
            ),
          ],
          if (incident.description.isNotEmpty) ...[
            const SizedBox(height: AtlasSpace.md),
            Text(
              incident.description,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AtlasColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color color;
  const _MetaPill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AtlasRadius.round),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final CustomerIncident incident;
  const _DetailGrid({required this.incident});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return Container(
      padding: const EdgeInsets.all(AtlasSpace.xl),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      child: Column(
        children: [
          _kv('Source (from)', incident.from.isNotEmpty ? incident.from : '—'),
          _kv('Severity',
              incident.severity.isNotEmpty ? incident.severity : '—'),
          _kv('Assignee', incident.assignedName ?? '—'),
          _kv(
            'Created',
            incident.createdAt != null ? fmt.format(incident.createdAt!) : '—',
          ),
          _kv(
            'Acknowledged',
            incident.acknowledgedAt != null
                ? '${fmt.format(incident.acknowledgedAt!)}'
                    '${incident.acknowledgedByName != null ? " · by ${incident.acknowledgedByName}" : ""}'
                : '—',
          ),
          _kv('MTTA', _formatDuration(incident.mttaSeconds)),
          _kv(
            'Resolved',
            incident.resolvedAt != null
                ? '${fmt.format(incident.resolvedAt!)}'
                    '${incident.resolvedByName != null ? " · by ${incident.resolvedByName}" : ""}'
                : '—',
          ),
          _kv('MTTR', _formatDuration(incident.mttrSeconds)),
          if (incident.resolutionReason != null &&
              incident.resolutionReason!.isNotEmpty)
            _kv('Resolution reason', incident.resolutionReason!),
          if (incident.tags.isNotEmpty) _kv('Tags', incident.tags.join(', ')),
        ],
      ),
    );
  }
}

Widget _kv(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AtlasColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AtlasColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
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

class _NotesSection extends StatelessWidget {
  final String incidentId;
  const _NotesSection({required this.incidentId});

  @override
  Widget build(BuildContext context) {
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
          const Text('Responder notes', style: AtlasText.h3),
          const SizedBox(height: AtlasSpace.md),
          StreamBuilder<List<CustomerIncidentNote>>(
            stream: CustomerIncidentService.instance.watchNotes(incidentId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final notes = snap.data ?? const [];
              if (notes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No notes yet.', style: AtlasText.smallMuted),
                );
              }
              return Column(
                children: notes.map((n) => _NoteRow(note: n)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final CustomerIncidentNote note;
  const _NoteRow({required this.note});
  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AtlasColors.tableHeaderBg,
        borderRadius: BorderRadius.circular(AtlasRadius.md),
        border: Border.all(color: AtlasColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                note.authorName,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (note.createdAt != null)
                Text(
                  fmt.format(note.createdAt!),
                  style: const TextStyle(
                      fontSize: 11, color: AtlasColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note.body,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
