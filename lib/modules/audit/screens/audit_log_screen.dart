import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/audit_log_model.dart';
import '../../../core/models/staff_user_model.dart';
import '../../../modules/auth/controller/auth_controller.dart';
import '../../../theme/atlas_colors.dart';
import '../../../utils/routes.dart';
import '../../../widgets/app_shell.dart';
import '../controller/audit_log_controller.dart';

class AuditLogScreen extends StatelessWidget {
  AuditLogScreen({super.key});

  final controller = Get.put(AuditLogController());

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final staff = auth.currentStaff.value;

    // Permission gate — admin/owner only
    if (staff == null || !staff.role.isAtLeast(StaffRole.admin)) {
      return AppShell(
        currentRoute: AtlasRoutes.audit,
        pageTitle: 'Audit Log',
        child: _AccessDenied(),
      );
    }

    return AppShell(
      currentRoute: AtlasRoutes.audit,
      pageTitle: 'Audit log',
      pageSubtitle:
          'Immutable record of every staff action. Cannot be edited or deleted.',
      actions: [
        Obx(() => OutlinedButton.icon(
              onPressed: controller.filtered.isEmpty
                  ? null
                  : () => controller.exportCsv(),
              icon: const Icon(Icons.download, size: 14),
              label: Text('Export CSV (${controller.filtered.length})'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: const Size(0, 36),
                textStyle: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            )),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Filters(controller: controller),
          const SizedBox(height: 16),

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
                      'No audit entries match these filters.',
                      style: TextStyle(color: AtlasColors.textMuted),
                    ),
                  ),
                );
              }
              return _AuditTable(rows: controller.filtered);
            }),
          ),
        ],
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(60),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.lock_outline, size: 48, color: AtlasColors.danger),
          SizedBox(height: 14),
          Text(
            'Access denied',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AtlasColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Only Admin or Owner staff can view the audit log.',
            style: TextStyle(color: AtlasColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final AuditLogController controller;
  const _Filters({required this.controller});

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
                hintText: 'Search staff, action, target, reason…',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
              ),
            ),
          ),
          Obx(() => _Dropdown(
                label: 'Action',
                value: controller.actionFilter,
                options: {
                  'all': 'All actions',
                  for (final a in controller.availableActions) a: a,
                },
              )),
          Obx(() => _Dropdown(
                label: 'Staff',
                value: controller.staffFilter,
                options: {
                  'all': 'All staff',
                  for (final s in controller.availableStaff) s: s,
                },
              )),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final RxString value;
  final Map<String, String> options;
  const _Dropdown({
    required this.label,
    required this.value,
    required this.options,
  });

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
          const SizedBox(width: 6),
          Obx(() => DropdownButton<String>(
                value: options.containsKey(value.value) ? value.value : 'all',
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

class _AuditTable extends StatelessWidget {
  final List<AuditLog> rows;
  const _AuditTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, HH:mm:ss');
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
          dataTextStyle: const TextStyle(fontSize: 12, color: AtlasColors.textPrimary),
          columns: const [
            DataColumn(label: Text('TIMESTAMP')),
            DataColumn(label: Text('STAFF')),
            DataColumn(label: Text('ROLE')),
            DataColumn(label: Text('ACTION')),
            DataColumn(label: Text('TARGET')),
            DataColumn(label: Text('REASON')),
          ],
          rows: rows.map((l) {
            return DataRow(
              cells: [
                DataCell(Text(
                  df.format(l.timestamp),
                  style: const TextStyle(color: AtlasColors.textSecondary),
                )),
                DataCell(Text(l.staffEmail, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(_RoleChip(role: l.staffRole)),
                DataCell(_ActionChip(action: l.action)),
                DataCell(SizedBox(
                  width: 240,
                  child: Text(
                    l.targetDisplay ?? l.targetId,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                DataCell(SizedBox(
                  width: 280,
                  child: Text(
                    l.reason ?? '—',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AtlasColors.textSecondary),
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AtlasColors.textSecondary,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String action;
  const _ActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    final isSensitive = action.contains('IMPERSONAT') ||
        action.contains('DISABLED') ||
        action.contains('REVOKED') ||
        action.contains('REMOVED');
    final isPii = action.contains('VIEWED_PII');

    final colors = isSensitive
        ? (AtlasColors.danger, AtlasColors.dangerSoft)
        : isPii
            ? (AtlasColors.warning, AtlasColors.warningSoft)
            : (AtlasColors.accent, AtlasColors.accentSoft);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        action,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: colors.$1,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
