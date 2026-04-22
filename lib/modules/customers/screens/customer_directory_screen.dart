import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../theme/atlas_colors.dart';
import '../../../utils/routes.dart';
import '../../../widgets/app_shell.dart';
import '../controller/customer_controller.dart';

class CustomerDirectoryScreen extends StatelessWidget {
  CustomerDirectoryScreen({super.key});

  final controller = Get.put(CustomerController());

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AtlasRoutes.customers,
      pageTitle: 'Customers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Customer organizations',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AtlasColors.textPrimary,
                  ),
                ),
              ),
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AtlasColors.accentSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${controller.filtered.length} of ${controller.all.length}',
                      style: const TextStyle(
                        color: AtlasColors.accentHover,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 16),

          // Toolbar
          _Toolbar(controller: controller),
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
                return const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(
                    child: Text(
                      'No organizations match your filters.',
                      style: TextStyle(color: AtlasColors.textMuted),
                    ),
                  ),
                );
              }
              return _CustomerTable(controller: controller);
            }),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final CustomerController controller;
  const _Toolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                hintText: 'Search by name, email, website…',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
              ),
            ),
          ),
          _FilterDropdown(
            label: 'Plan',
            value: controller.planFilter,
            options: const {
              'all': 'All plans',
              'free': 'Free',
              'plus': 'Plus',
              'premium': 'Premium',
            },
          ),
          _FilterDropdown(
            label: 'Status',
            value: controller.statusFilter,
            options: const {
              'all': 'All statuses',
              'active': 'Active',
              'past_due': 'Past due',
              'cancelled': 'Cancelled',
            },
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final RxString value;
  final Map<String, String> options;
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
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
              DropdownButton<String>(
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
              ),
            ],
          ),
        ));
  }
}

class _CustomerTable extends StatelessWidget {
  final CustomerController controller;
  const _CustomerTable({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = controller.filtered;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 296,
          ),
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(AtlasColors.tableHeaderBg),
            headingTextStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AtlasColors.textSecondary,
              letterSpacing: 0.4,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 13,
              color: AtlasColors.textPrimary,
            ),
            columns: const [
              DataColumn(label: Text('ORG NAME')),
              DataColumn(label: Text('EMAIL')),
              DataColumn(label: Text('INDUSTRY')),
              DataColumn(label: Text('MEMBERS')),
              DataColumn(label: Text('PLAN')),
              DataColumn(label: Text('CREATED')),
              DataColumn(label: Text('')),
            ],
            rows: rows.map((o) => _row(context, o)).toList(),
          ),
        ),
      );
    });
  }

  DataRow _row(BuildContext context, org) {
    final df = DateFormat('MMM d, yyyy');
    return DataRow(
      cells: [
        DataCell(Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AtlasColors.accentSoft,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.business, size: 16, color: AtlasColors.accent),
            ),
            const SizedBox(width: 10),
            Text(org.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        )),
        DataCell(Text(org.email ?? '—', style: const TextStyle(color: AtlasColors.textSecondary))),
        DataCell(Text(org.industry ?? '—', style: const TextStyle(color: AtlasColors.textSecondary))),
        DataCell(Text('${org.memberCount > 0 ? org.memberCount : '—'}')),
        DataCell(_PlanPill(plan: org.plan ?? 'free')),
        DataCell(Text(
          org.createdAt != null ? df.format(org.createdAt!) : '—',
          style: const TextStyle(color: AtlasColors.textSecondary),
        )),
        DataCell(IconButton(
          icon: const Icon(Icons.chevron_right, size: 18),
          color: AtlasColors.textMuted,
          onPressed: () {
            controller.openCustomer(org.id);
            Get.toNamed(AtlasRoutes.customerDetail, arguments: org.id);
          },
        )),
      ],
    );
  }
}

class _PlanPill extends StatelessWidget {
  final String plan;
  const _PlanPill({required this.plan});

  @override
  Widget build(BuildContext context) {
    final colors = switch (plan) {
      'premium' => (AtlasColors.accent, AtlasColors.accentSoft),
      'plus' => (AtlasColors.info, AtlasColors.infoSoft),
      _ => (AtlasColors.textMuted, const Color(0xFFF1F5F9)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        plan.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: colors.$1,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
