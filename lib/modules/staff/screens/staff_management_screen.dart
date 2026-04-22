import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/staff_user_model.dart';
import '../../../core/services/staff_management_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../utils/routes.dart';
import '../../../widgets/app_shell.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/staff_controller.dart';
import '../widgets/add_staff_dialog.dart';

class StaffManagementScreen extends StatelessWidget {
  StaffManagementScreen({super.key});

  final controller = Get.put(StaffController());

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final me = auth.currentStaff.value;

    if (me == null || !me.role.isAtLeast(StaffRole.admin)) {
      return AppShell(
        currentRoute: AtlasRoutes.staff,
        pageTitle: 'Staff',
        child: _AccessDenied(),
      );
    }

    return AppShell(
      currentRoute: AtlasRoutes.staff,
      pageTitle: 'Staff',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff & permissions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AtlasColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage who has Atlas access and what they can do.',
                      style: TextStyle(color: AtlasColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => showAddStaffDialog(context),
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Add staff'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _Toolbar(controller: controller),
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
                      'No staff match these filters.',
                      style: TextStyle(color: AtlasColors.textMuted),
                    ),
                  ),
                );
              }
              return _StaffTable(
                rows: controller.filtered,
                currentStaff: me,
              );
            }),
          ),

          const SizedBox(height: 16),
          _PermissionMatrix(),
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
            'Only Admin or Owner staff can manage other staff.',
            style: TextStyle(color: AtlasColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final StaffController controller;
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
                hintText: 'Search by name or email…',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
              ),
            ),
          ),
          _Filter(
            label: 'Role',
            value: controller.roleFilter,
            options: {
              'all': 'All roles',
              for (final r in StaffRole.values) r.id: r.label,
            },
          ),
          Obx(() => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: controller.showDisabled.value,
                    activeThumbColor: AtlasColors.accent,
                    onChanged: (v) => controller.showDisabled.value = v,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Show disabled',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AtlasColors.textSecondary,
                    ),
                  ),
                ],
              )),
        ],
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

class _StaffTable extends StatelessWidget {
  final List<StaffUser> rows;
  final StaffUser currentStaff;
  const _StaffTable({required this.rows, required this.currentStaff});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy');
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
            DataColumn(label: Text('NAME')),
            DataColumn(label: Text('EMAIL')),
            DataColumn(label: Text('ROLE')),
            DataColumn(label: Text('MFA')),
            DataColumn(label: Text('LAST LOGIN')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('')),
          ],
          rows: rows.map((s) {
            final isMe = s.uid == currentStaff.uid;
            return DataRow(
              cells: [
                DataCell(Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AtlasColors.accentSoft,
                      child: Text(
                        s.displayName.isNotEmpty
                            ? s.displayName[0].toUpperCase()
                            : s.email[0].toUpperCase(),
                        style: const TextStyle(
                          color: AtlasColors.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      s.displayName.isEmpty ? '—' : s.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (isMe)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AtlasColors.infoSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: AtlasColors.info,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                )),
                DataCell(Text(
                  s.email,
                  style: const TextStyle(color: AtlasColors.textSecondary),
                )),
                DataCell(_RoleDropdown(
                  staff: s,
                  canEdit: !isMe && currentStaff.role.isAtLeast(StaffRole.owner),
                )),
                DataCell(s.mfaEnrolled
                    ? const Icon(Icons.check_circle, size: 16, color: AtlasColors.success)
                    : const Icon(Icons.warning_amber_rounded,
                        size: 16, color: AtlasColors.warning)),
                DataCell(Text(
                  s.lastLoginAt != null ? df.format(s.lastLoginAt!) : '—',
                  style: const TextStyle(color: AtlasColors.textSecondary, fontSize: 12),
                )),
                DataCell(_StatusPill(disabled: s.disabled)),
                DataCell(_RowActions(
                  staff: s,
                  isMe: isMe,
                  currentRole: currentStaff.role,
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  final StaffUser staff;
  final bool canEdit;
  const _RoleDropdown({required this.staff, required this.canEdit});

  @override
  Widget build(BuildContext context) {
    if (!canEdit) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          staff.role.label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AtlasColors.textSecondary,
          ),
        ),
      );
    }
    return DropdownButton<StaffRole>(
      value: staff.role,
      isDense: true,
      underline: const SizedBox.shrink(),
      style: const TextStyle(
        color: AtlasColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      items: StaffRole.values
          .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
          .toList(),
      onChanged: (newRole) async {
        if (newRole == null) return;
        await StaffManagementService.instance.changeRole(staff, newRole);
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool disabled;
  const _StatusPill({required this.disabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: disabled ? AtlasColors.dangerSoft : AtlasColors.successSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        disabled ? 'DISABLED' : 'ACTIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: disabled ? AtlasColors.danger : AtlasColors.success,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  final StaffUser staff;
  final bool isMe;
  final StaffRole currentRole;
  const _RowActions({
    required this.staff,
    required this.isMe,
    required this.currentRole,
  });

  @override
  Widget build(BuildContext context) {
    if (isMe) return const SizedBox(width: 100);
    if (!currentRole.isAtLeast(StaffRole.owner)) return const SizedBox(width: 100);

    return TextButton.icon(
      onPressed: () async {
        final confirmed = await _confirm(context, staff);
        if (!confirmed) return;
        await StaffManagementService.instance.setDisabled(staff, !staff.disabled);
      },
      icon: Icon(
        staff.disabled ? Icons.check_circle_outline : Icons.block,
        size: 14,
      ),
      label: Text(staff.disabled ? 'Re-enable' : 'Disable'),
      style: TextButton.styleFrom(
        foregroundColor: staff.disabled ? AtlasColors.success : AtlasColors.danger,
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, StaffUser staff) async {
    final action = staff.disabled ? 're-enable' : 'disable';
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Confirm ${action == 'disable' ? 'disable' : 're-enable'}',
        ),
        content: Text(
          staff.disabled
              ? 'Restore Atlas access for ${staff.email}?'
              : 'Revoke Atlas access for ${staff.email}? They will be signed out and unable to log in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  staff.disabled ? AtlasColors.success : AtlasColors.danger,
            ),
            child: Text(staff.disabled ? 'Re-enable' : 'Disable'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ─────────────────────────────────────────────────────────────────────
// Permission matrix reference card
// ─────────────────────────────────────────────────────────────────────

class _PermissionMatrix extends StatelessWidget {
  static final _capabilities = <_Capability>[
    _Capability('View customer directory', StaffRole.l1Support),
    _Capability('View customer detail', StaffRole.l1Support),
    _Capability('View PII (full email/phone)', StaffRole.l2Support),
    _Capability('Impersonate (read-only)', StaffRole.l2Support),
    _Capability('Impersonate (read-write)', StaffRole.engineer),
    _Capability('Create/edit support tickets', StaffRole.l1Support),
    _Capability('Reset customer password', StaffRole.l2Support),
    _Capability('Edit customer subscription', StaffRole.engineer),
    _Capability('Disable customer account', StaffRole.admin),
    _Capability('Manage staff (add/disable)', StaffRole.admin),
    _Capability('View staff audit log', StaffRole.admin),
    _Capability('Change another admin\'s role', StaffRole.owner),
    _Capability('Delete customer data permanently', StaffRole.owner),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AtlasColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Permission matrix',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AtlasColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 40,
              headingRowColor: WidgetStatePropertyAll(AtlasColors.tableHeaderBg),
              headingTextStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AtlasColors.textSecondary,
                letterSpacing: 0.4,
              ),
              dataTextStyle: const TextStyle(fontSize: 12),
              columns: [
                const DataColumn(label: Text('CAPABILITY')),
                ...StaffRole.values.map((r) => DataColumn(label: Text(r.label.toUpperCase()))),
              ],
              rows: _capabilities.map((cap) {
                return DataRow(
                  cells: [
                    DataCell(Text(cap.label)),
                    ...StaffRole.values.map((r) {
                      final has = r.isAtLeast(cap.minRole);
                      return DataCell(Center(
                        child: Icon(
                          has ? Icons.check : Icons.remove,
                          size: 14,
                          color: has ? AtlasColors.success : AtlasColors.cardBorder,
                        ),
                      ));
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Capability {
  final String label;
  final StaffRole minRole;
  const _Capability(this.label, this.minRole);
}
