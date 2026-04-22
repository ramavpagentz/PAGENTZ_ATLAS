// Atlas is a web-only Flutter app; dart:html is intentional for the CSV
// download anchor element. Migrate to package:web + dart:js_interop later.
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:csv/csv.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/models/staff_user_model.dart';
import '../../auth/controller/staff_auth_controller.dart';
import '../controller/audit_log_controller.dart';
import '../models/audit_entry_model.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  bool _canView(StaffAuthController auth) {
    final role = auth.staffUser.value?.staffRole;
    return role == StaffRole.admin || role == StaffRole.owner;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<StaffAuthController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed('/home'),
        ),
        title: const Text('Staff audit log'),
      ),
      body: Obx(() {
        if (!_canView(auth)) {
          return const _AccessDenied();
        }
        // Lazily put controller only after access is confirmed.
        final c = Get.put(AuditLogController());
        return _AuditLogBody(c: c);
      }),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 48, color: Colors.amber),
                const SizedBox(height: 12),
                Text('Audit log is restricted',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Only Atlas staff with the admin or owner role can view the staff audit log.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => Get.offAllNamed('/home'),
                  child: const Text('Back to dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuditLogBody extends StatelessWidget {
  final AuditLogController c;
  const _AuditLogBody({required this.c});

  void _exportCsv() {
    final rows = <List<String>>[
      AuditEntry.csvHeader,
      ...c.entries.map((e) => e.toCsvRow()),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now().toUtc());
    final filename = 'atlas_audit_${ts}_utc.csv';

    final blob = html.Blob(<String>[csv], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterBar(c: c, onExport: _exportCsv),
        Expanded(
          child: Obx(() {
            if (c.loadingFirstPage.value && c.entries.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (c.error.value != null && c.entries.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    c.error.value!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (c.entries.isEmpty) {
              return const Center(child: Text('No audit entries match.'));
            }
            return _AuditTable(c: c);
          }),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final AuditLogController c;
  final VoidCallback onExport;
  const _FilterBar({required this.c, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Obx(() {
            final actions = c.knownActions;
            return SizedBox(
              width: 240,
              child: DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: c.filter.value.action,
                decoration: const InputDecoration(
                  labelText: 'Action',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...actions.map((a) =>
                      DropdownMenuItem(value: a, child: Text(a))),
                ],
                onChanged: c.setActionFilter,
              ),
            );
          }),
          SizedBox(
            width: 280,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Target ID (org / user / ticket)',
                hintText: 'Filter by exact targetId',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: c.filter.value.targetId == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => c.setTargetFilter(null),
                      ),
              ),
              onSubmitted: (v) =>
                  c.setTargetFilter(v.trim().isEmpty ? null : v.trim()),
            ),
          ),
          Obx(() => Text(
                '${c.entries.length} entr${c.entries.length == 1 ? "y" : "ies"} loaded'
                '${c.exhausted.value ? "" : " (more available)"}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              )),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: c.clearFilters,
            icon: const Icon(Icons.filter_alt_off, size: 18),
            label: const Text('Clear'),
          ),
          OutlinedButton.icon(
            onPressed: c.reload,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
          FilledButton.icon(
            onPressed: c.entries.isEmpty ? null : onExport,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }
}

class _AuditTable extends StatelessWidget {
  final AuditLogController c;
  const _AuditTable({required this.c});

  String _fmt(DateTime? t) {
    if (t == null) return '—';
    final local = t.toLocal();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(local);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: DataTable2(
              columnSpacing: 18,
              horizontalMargin: 12,
              minWidth: 1100,
              columns: const [
                DataColumn2(label: Text('Time (local)'), size: ColumnSize.M),
                DataColumn2(label: Text('Staff'), size: ColumnSize.L),
                DataColumn2(label: Text('Action'), size: ColumnSize.L),
                DataColumn2(label: Text('Target type'), size: ColumnSize.S),
                DataColumn2(label: Text('Target'), size: ColumnSize.L),
                DataColumn2(label: Text('Reason'), size: ColumnSize.L),
              ],
              rows: c.entries
                  .map((e) => DataRow2(
                        cells: [
                          DataCell(Text(_fmt(e.timestamp))),
                          DataCell(Text(e.staffEmail ?? e.staffUid ?? '—',
                              overflow: TextOverflow.ellipsis)),
                          DataCell(Text(e.action,
                              overflow: TextOverflow.ellipsis)),
                          DataCell(Text(e.targetType ?? '—')),
                          DataCell(Text(e.targetDisplay ?? e.targetId ?? '—',
                              overflow: TextOverflow.ellipsis)),
                          DataCell(Text(e.reason ?? '—',
                              overflow: TextOverflow.ellipsis)),
                        ],
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            if (c.exhausted.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('All entries loaded.',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: OutlinedButton.icon(
                onPressed: c.loadingMore.value ? null : c.loadMore,
                icon: c.loadingMore.value
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.expand_more, size: 18),
                label: Text(c.loadingMore.value ? 'Loading…' : 'Load more'),
              ),
            );
          }),
        ],
      ),
    );
  }
}
