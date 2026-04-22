import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../audit/models/audit_entry_model.dart';
import '../../audit/services/audit_query_service.dart';

/// Activity timeline for a single customer org.
///
/// Renders two streams chronologically:
///   1. Staff actions targeting this org, from Firestore `staff_audit_logs`.
///   2. Customer-side activity from the main app's Postgres backend
///      (Activity Logs / Pagers / AMS / IPAM modules) — currently stubbed
///      until the internal backend API endpoint is built. See the backend
///      logs architecture spec.
class CustomerActivityTimeline extends StatefulWidget {
  final String orgId;
  const CustomerActivityTimeline({super.key, required this.orgId});

  @override
  State<CustomerActivityTimeline> createState() =>
      _CustomerActivityTimelineState();
}

class _CustomerActivityTimelineState extends State<CustomerActivityTimeline> {
  final _svc = AuditQueryService.instance;
  bool _loading = true;
  String? _error;
  List<AuditEntry> _staffEvents = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _svc.fetchPage(
        filter: AuditQueryFilter(targetId: widget.orgId),
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _staffEvents = page.entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load staff activity: $e';
        _loading = false;
      });
    }
  }

  String _fmt(DateTime? t) {
    if (t == null) return '—';
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(t.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StaffEventsCard(events: _staffEvents, fmt: _fmt, onRefresh: _load),
            const SizedBox(height: 16),
            const _CustomerEventsPlaceholder(),
          ],
        ),
      ),
    );
  }
}

class _StaffEventsCard extends StatelessWidget {
  final List<AuditEntry> events;
  final String Function(DateTime?) fmt;
  final VoidCallback onRefresh;
  const _StaffEventsCard({
    required this.events,
    required this.fmt,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Staff actions on this customer',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Refresh',
                  onPressed: onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Reads from Firestore staff_audit_logs filtered to this org.',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
            const Divider(height: 24),
            if (events.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No staff actions recorded for this customer yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
              )
            else
              ...events.map((e) => _EventRow(entry: e, fmt: fmt)),
          ],
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final AuditEntry entry;
  final String Function(DateTime?) fmt;
  const _EventRow({required this.entry, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.fiber_manual_record,
                size: 8, color: Colors.indigoAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.action,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(fmt(entry.timestamp),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.staffEmail ?? entry.staffUid ?? "unknown"}'
                  '${entry.reason == null ? "" : " — ${entry.reason}"}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerEventsPlaceholder extends StatelessWidget {
  const _CustomerEventsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline_outlined,
                    size: 18, color: Colors.white60),
                const SizedBox(width: 8),
                Text('Customer-side activity',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Pending backend integration: needs an internal Postgres-backed API endpoint exposing the unified Activity Logs / Pagers / AMS / IPAM modules per org. Atlas will merge those events here chronologically alongside staff actions above. See the backend logs architecture spec.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
