import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/customer_org_model.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
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
      pageSubtitle: 'Browse, search, and open any customer organization.',
      actions: [
        Obx(() => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AtlasSpace.md, vertical: 6),
              decoration: BoxDecoration(
                color: AtlasColors.pillNeutral,
                borderRadius: BorderRadius.circular(AtlasRadius.round),
              ),
              child: Text(
                '${controller.filtered.length} of ${controller.all.length}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AtlasColors.pillNeutralText,
                  letterSpacing: 0.2,
                ),
              ),
            )),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar
          _Toolbar(controller: controller),
          const SizedBox(height: AtlasSpace.lg),

          // Table
          Container(
            decoration: BoxDecoration(
              color: AtlasColors.cardBg,
              border: Border.all(color: AtlasColors.cardBorder),
              borderRadius: BorderRadius.circular(AtlasRadius.lg),
              boxShadow: AtlasElevation.sm,
            ),
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.all(AtlasSpace.huge),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.filtered.isEmpty) {
                return _EmptyState(
                  hasFilters: controller.query.value.isNotEmpty ||
                      controller.planFilter.value != 'all' ||
                      controller.statusFilter.value != 'all',
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

// ─── TOOLBAR ────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  final CustomerController controller;
  const _Toolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AtlasSpace.md),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
        boxShadow: AtlasElevation.sm,
      ),
      child: Wrap(
        spacing: AtlasSpace.sm + 2,
        runSpacing: AtlasSpace.sm + 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              onChanged: (v) => controller.query.value = v,
              decoration: const InputDecoration(
                hintText: 'Search organizations…',
                prefixIcon: Icon(Icons.search, size: 17),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: AtlasSpace.sm, vertical: AtlasSpace.sm + 2),
              ),
            ),
          ),
          _FilterChip(
            label: 'Plan',
            value: controller.planFilter,
            options: const {
              'all': 'All plans',
              'free': 'Free',
              'plus': 'Plus',
              'premium': 'Premium',
            },
          ),
          _FilterChip(
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

class _FilterChip extends StatelessWidget {
  final String label;
  final RxString value;
  final Map<String, String> options;
  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: AtlasSpace.md, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AtlasColors.cardBorder),
            borderRadius: BorderRadius.circular(AtlasRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$label: ',
                  style: AtlasText.tiny.copyWith(
                      color: AtlasColors.textSecondary,
                      fontWeight: FontWeight.w500)),
              DropdownButton<String>(
                value: options.containsKey(value.value) ? value.value : 'all',
                onChanged: (v) {
                  if (v != null) value.value = v;
                },
                underline: const SizedBox.shrink(),
                isDense: true,
                style: const TextStyle(
                  color: AtlasColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                items: options.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
              ),
            ],
          ),
        ));
  }
}

// ─── TABLE ──────────────────────────────────────────────────────────────

class _CustomerTable extends StatelessWidget {
  final CustomerController controller;
  const _CustomerTable({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = controller.filtered;
      return Column(
        children: [
          // Header row
          Container(
            decoration: const BoxDecoration(
              color: AtlasColors.tableHeaderBg,
              border: Border(bottom: BorderSide(color: AtlasColors.tableBorder)),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AtlasSpace.xl, vertical: AtlasSpace.md - 2),
            child: const Row(
              children: [
                Expanded(flex: 4, child: _HeaderCell('Organization')),
                Expanded(flex: 3, child: _HeaderCell('Email')),
                Expanded(flex: 2, child: _HeaderCell('Industry')),
                SizedBox(width: 70, child: _HeaderCell('Members')),
                SizedBox(width: 80, child: _HeaderCell('Plan')),
                SizedBox(width: 100, child: _HeaderCell('Created')),
                SizedBox(width: 30),
              ],
            ),
          ),
          // Data rows
          ...rows.asMap().entries.map((e) => _DataRow(
                org: e.value,
                isLast: e.key == rows.length - 1,
              )),
        ],
      );
    });
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
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: AtlasColors.textMuted,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _DataRow extends StatefulWidget {
  final CustomerOrg org;
  final bool isLast;
  const _DataRow({required this.org, required this.isLast});

  @override
  State<_DataRow> createState() => _DataRowState();
}

class _DataRowState extends State<_DataRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy');
    final org = widget.org;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final controller = Get.find<CustomerController>();
          controller.openCustomer(org.id);
          Get.toNamed(AtlasRoutes.customerDetail, arguments: org.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: _hover ? AtlasColors.tableRowHover : Colors.transparent,
            border: Border(
              bottom: widget.isLast
                  ? BorderSide.none
                  : const BorderSide(color: AtlasColors.cardBorderSubtle),
            ),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AtlasSpace.xl, vertical: AtlasSpace.md + 2),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AtlasColors.accentSoft,
                        borderRadius: BorderRadius.circular(AtlasRadius.sm),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.business_rounded,
                          size: 14, color: AtlasColors.accent),
                    ),
                    const SizedBox(width: AtlasSpace.md),
                    Expanded(
                      child: Text(org.name,
                          style: AtlasText.body.copyWith(
                              fontWeight: FontWeight.w600, fontSize: 13.5),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  org.email ?? '—',
                  style: AtlasText.small,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  org.industry ?? '—',
                  style: AtlasText.small,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  '${org.memberCount > 0 ? org.memberCount : '—'}',
                  style: AtlasText.body.copyWith(fontSize: 13),
                ),
              ),
              SizedBox(
                width: 80,
                child: _PlanPill(plan: org.plan ?? 'free'),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  org.createdAt != null ? df.format(org.createdAt!) : '—',
                  style: AtlasText.tiny,
                ),
              ),
              const SizedBox(
                width: 30,
                child: Icon(Icons.chevron_right,
                    size: 16, color: AtlasColors.textMuted),
              ),
            ],
          ),
        ),
      ),
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
      _ => (AtlasColors.pillNeutralText, AtlasColors.pillNeutral),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AtlasSpace.sm, vertical: 3),
        decoration: BoxDecoration(
          color: colors.$2,
          borderRadius: BorderRadius.circular(AtlasRadius.round),
        ),
        child: Text(
          plan.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: colors.$1,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

// ─── EMPTY STATE ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AtlasSpace.huge),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AtlasColors.pillNeutral,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                hasFilters ? Icons.filter_list_off : Icons.business_outlined,
                size: 26,
                color: AtlasColors.textMuted,
              ),
            ),
            const SizedBox(height: AtlasSpace.md),
            Text(
              hasFilters
                  ? 'No customers match your filters'
                  : 'No customer organizations yet',
              style: AtlasText.body
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filter values.'
                  : 'Customers will appear here once they sign up.',
              style: AtlasText.smallMuted,
            ),
          ],
        ),
      ),
    );
  }
}
