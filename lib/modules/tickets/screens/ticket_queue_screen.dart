import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../theme/atlas_colors.dart';
import '../../../utils/routes.dart';
import '../../../widgets/app_shell.dart';
import '../controller/ticket_controller.dart';
import '../widgets/ticket_chips.dart';

class TicketQueueScreen extends StatelessWidget {
  TicketQueueScreen({super.key});

  final controller = Get.put(TicketController());

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AtlasRoutes.tickets,
      pageTitle: 'Support Tickets',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading + KPIs
          const Text(
            'Support queue',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AtlasColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Track every customer query — assign, respond, resolve.',
            style: TextStyle(color: AtlasColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 18),

          // Status KPIs
          Obx(() => Row(
                children: [
                  _Kpi(
                    label: 'NEW',
                    count: controller.countByStatus(TicketStatus.newTicket),
                    color: AtlasColors.info,
                  ),
                  const SizedBox(width: 12),
                  _Kpi(
                    label: 'OPEN',
                    count: controller.countByStatus(TicketStatus.open),
                    color: AtlasColors.warning,
                  ),
                  const SizedBox(width: 12),
                  _Kpi(
                    label: 'AWAITING CUSTOMER',
                    count: controller.countByStatus(TicketStatus.pendingCustomer),
                    color: Colors.purple.shade700,
                  ),
                  const SizedBox(width: 12),
                  _Kpi(
                    label: 'RESOLVED',
                    count: controller.countByStatus(TicketStatus.resolved),
                    color: AtlasColors.success,
                  ),
                ],
              )),
          const SizedBox(height: 18),

          // Toolbar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AtlasColors.cardBg,
              border: Border.all(color: AtlasColors.cardBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    onChanged: (v) => controller.query.value = v,
                    decoration: const InputDecoration(
                      hintText: 'Search by subject, org, ticket #…',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                  ),
                ),
                _Filter(
                  label: 'Status',
                  value: controller.statusFilter,
                  options: {
                    'all': 'All',
                    for (final s in TicketStatus.values) s.id: s.label,
                  },
                ),
                _Filter(
                  label: 'Priority',
                  value: controller.priorityFilter,
                  options: {
                    'all': 'All',
                    for (final p in TicketPriority.values) p.id: p.label,
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Table
          Container(
            decoration: BoxDecoration(
              color: AtlasColors.cardBg,
              border: Border.all(color: AtlasColors.cardBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 40, color: AtlasColors.textMuted),
                      const SizedBox(height: 10),
                      Text(
                        controller.all.isEmpty
                            ? 'No tickets yet. Create one from a customer detail page.'
                            : 'No tickets match these filters.',
                        style: const TextStyle(
                          color: AtlasColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _TicketTable(rows: controller.filtered);
            }),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _Kpi({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AtlasColors.cardBg,
          border: Border.all(color: AtlasColors.cardBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AtlasColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AtlasColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  final String label;
  final RxString value;
  final Map<String, String> options;
  const _Filter({required this.label, required this.value, required this.options});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              color: AtlasColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Obx(() => DropdownButton<String>(
                value: value.value,
                onChanged: (v) {
                  if (v != null) value.value = v;
                },
                underline: const SizedBox.shrink(),
                isDense: true,
                style: const TextStyle(
                  color: AtlasColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                items: options.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
              )),
        ],
      ),
    );
  }
}

class _TicketTable extends StatelessWidget {
  final List<SupportTicket> rows;
  const _TicketTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 296,
        ),
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(AtlasColors.tableHeaderBg),
          headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AtlasColors.textSecondary,
            letterSpacing: 0.4,
          ),
          dataTextStyle: const TextStyle(fontSize: 13, color: AtlasColors.textPrimary),
          columns: const [
            DataColumn(label: Text('TICKET')),
            DataColumn(label: Text('SUBJECT')),
            DataColumn(label: Text('ORG')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('PRIORITY')),
            DataColumn(label: Text('ASSIGNED')),
            DataColumn(label: Text('UPDATED')),
            DataColumn(label: Text('')),
          ],
          rows: rows.map((t) {
            return DataRow(
              onSelectChanged: (_) =>
                  Get.toNamed(AtlasRoutes.ticketDetail, arguments: t.id),
              cells: [
                DataCell(Text(
                  t.ticketNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AtlasColors.textSecondary,
                  ),
                )),
                DataCell(SizedBox(
                  width: 280,
                  child: Text(
                    t.subject,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                DataCell(Text(
                  t.orgName,
                  style: const TextStyle(color: AtlasColors.textSecondary, fontSize: 12),
                )),
                DataCell(StatusPill(status: t.status)),
                DataCell(PriorityPill(priority: t.priority)),
                DataCell(Text(
                  t.assignedToName ?? 'Unassigned',
                  style: TextStyle(
                    color: t.assignedToName == null
                        ? AtlasColors.textMuted
                        : AtlasColors.textPrimary,
                    fontStyle: t.assignedToName == null
                        ? FontStyle.italic
                        : FontStyle.normal,
                    fontSize: 12,
                  ),
                )),
                DataCell(Text(
                  df.format(t.updatedAt),
                  style: const TextStyle(color: AtlasColors.textSecondary, fontSize: 12),
                )),
                const DataCell(
                  Icon(Icons.chevron_right, size: 16, color: AtlasColors.textMuted),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
