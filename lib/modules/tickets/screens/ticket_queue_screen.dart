import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../auth/controller/staff_auth_controller.dart';
import '../controller/ticket_queue_controller.dart';
import '../models/ticket_models.dart';
import '../widgets/new_ticket_modal.dart';

class TicketQueueScreen extends StatelessWidget {
  const TicketQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<StaffAuthController>();
    final c = Get.put(TicketQueueController()
      ..setCurrentUid(auth.firebaseUser.value?.uid));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed('/home'),
        ),
        title: const Text('Support queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: c.reload,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(c: c),
          Expanded(
            child: Obx(() {
              if (c.loading.value && c.tickets.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (c.error.value != null && c.tickets.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(c.error.value!,
                        style: const TextStyle(color: Colors.redAccent)),
                  ),
                );
              }
              final rows = c.filtered;
              if (rows.isEmpty) {
                return const Center(
                  child: Text('No tickets match your filters.'),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: DataTable2(
                  columnSpacing: 18,
                  horizontalMargin: 12,
                  minWidth: 1100,
                  columns: const [
                    DataColumn2(label: Text('#'), size: ColumnSize.S),
                    DataColumn2(label: Text('Subject'), size: ColumnSize.L),
                    DataColumn2(label: Text('Customer'), size: ColumnSize.L),
                    DataColumn2(label: Text('Priority'), size: ColumnSize.S),
                    DataColumn2(label: Text('Status'), size: ColumnSize.S),
                    DataColumn2(label: Text('Assignee'), size: ColumnSize.M),
                    DataColumn2(label: Text('Updated'), size: ColumnSize.M),
                  ],
                  rows: rows
                      .map((t) => DataRow2(
                            onTap: () => Get.toNamed('/tickets/${t.id}'),
                            cells: [
                              DataCell(Text(t.ticketNumber,
                                  style: const TextStyle(
                                      fontFamily: 'monospace', fontSize: 12))),
                              DataCell(Text(t.subject,
                                  overflow: TextOverflow.ellipsis)),
                              DataCell(Text(t.orgName ?? '—',
                                  overflow: TextOverflow.ellipsis)),
                              DataCell(_PriorityChip(priority: t.priority)),
                              DataCell(_StatusChip(status: t.status)),
                              DataCell(Text(t.assignedToName ?? '—',
                                  overflow: TextOverflow.ellipsis)),
                              DataCell(Text(t.updatedAt == null
                                  ? '—'
                                  : DateFormat('MMM d HH:mm').format(
                                      t.updatedAt!.toLocal()))),
                            ],
                          ))
                      .toList(),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TicketQueueController c;
  const _FilterBar({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: Obx(() => DropdownButtonFormField<TicketStatus?>(
                  initialValue: c.statusFilter.value,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: <DropdownMenuItem<TicketStatus?>>[
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...TicketStatus.values.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        )),
                  ],
                  onChanged: c.setStatusFilter,
                )),
          ),
          SizedBox(
            width: 260,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'number, subject, org, reporter',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => c.search.value = v,
            ),
          ),
          Obx(() => FilterChip(
                label: const Text('Only mine'),
                selected: c.showOnlyMine.value,
                onSelected: c.toggleMineOnly,
              )),
          Obx(() => Text(
                '${c.filtered.length} of ${c.tickets.length}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              )),
          const Spacer(),
          FilledButton.icon(
            onPressed: () async {
              final t = await Get.dialog<SupportTicket>(
                  const NewTicketModal());
              if (t != null) {
                c.reload();
                Get.toNamed('/tickets/${t.id}');
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New ticket'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TicketStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (status) {
      case TicketStatus.newT:
        bg = Colors.blueAccent.withValues(alpha: 0.22);
        break;
      case TicketStatus.open:
        bg = Colors.amber.withValues(alpha: 0.22);
        break;
      case TicketStatus.pendingCustomer:
        bg = Colors.grey.withValues(alpha: 0.22);
        break;
      case TicketStatus.resolved:
        bg = Colors.green.withValues(alpha: 0.22);
        break;
      case TicketStatus.closed:
        bg = Colors.white.withValues(alpha: 0.08);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(status.label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final TicketPriority priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (priority) {
      case TicketPriority.low:
        bg = Colors.white.withValues(alpha: 0.08);
        break;
      case TicketPriority.normal:
        bg = Colors.blueAccent.withValues(alpha: 0.18);
        break;
      case TicketPriority.high:
        bg = Colors.amber.withValues(alpha: 0.25);
        break;
      case TicketPriority.urgent:
        bg = Colors.redAccent.withValues(alpha: 0.3);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(priority.label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: priority == TicketPriority.urgent
                  ? FontWeight.w700
                  : FontWeight.w500)),
    );
  }
}
