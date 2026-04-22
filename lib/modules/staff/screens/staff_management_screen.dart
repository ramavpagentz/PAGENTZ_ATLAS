import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/models/staff_user_model.dart';
import '../../auth/controller/staff_auth_controller.dart';
import '../controller/staff_management_controller.dart';
import '../models/staff_listing_model.dart';
import '../widgets/add_staff_modal.dart';

class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  bool _canManage(StaffAuthController auth) {
    final r = auth.staffUser.value?.staffRole;
    return r == StaffRole.admin || r == StaffRole.owner;
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
        title: const Text('Staff'),
        actions: [
          Obx(() => IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _canManage(auth)
                    ? Get.find<StaffManagementController>().reload
                    : null,
              )),
        ],
      ),
      body: Obx(() {
        if (!_canManage(auth)) return const _AccessDenied();
        final c = Get.put(StaffManagementController());
        return _Body(c: c, currentUid: auth.firebaseUser.value?.uid);
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
                Text('Staff management is restricted',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Only Atlas staff with the admin or owner role can add/remove other staff or change roles.',
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

class _Body extends StatelessWidget {
  final StaffManagementController c;
  final String? currentUid;
  const _Body({required this.c, required this.currentUid});

  String _fmt(DateTime? t) =>
      t == null ? '—' : DateFormat('yyyy-MM-dd HH:mm').format(t.toLocal());

  Future<void> _confirmDisable(StaffListing s) async {
    final reasonCtl = TextEditingController();
    final wantDisable = !s.disabled;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(wantDisable ? 'Disable staff' : 'Re-enable staff'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                wantDisable
                    ? 'Disable ${s.email}? They will be signed out immediately and unable to sign back in.'
                    : 'Re-enable ${s.email}? They will be able to sign in again with their existing TOTP factor.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reason (audited)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back<bool>(result: true),
            child: Text(wantDisable ? 'Disable' : 'Re-enable'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await c.setDisabled(
          uid: s.uid,
          disabled: wantDisable,
          reason: reasonCtl.text.trim().isEmpty
              ? null
              : reasonCtl.text.trim(),
        );
      } catch (e) {
        Get.snackbar('Failed', e.toString(),
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  Future<void> _changeRole(StaffListing s) async {
    StaffRole selected = s.role ?? StaffRole.l1Support;
    final reasonCtl = TextEditingController();
    final saved = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Change role for ${s.email}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: StatefulBuilder(
            builder: (ctx, setLocal) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Current: ${s.role?.value ?? "(none)"}'),
                const SizedBox(height: 12),
                DropdownButtonFormField<StaffRole>(
                  initialValue: selected,
                  decoration: const InputDecoration(
                    labelText: 'New role',
                    border: OutlineInputBorder(),
                  ),
                  items: StaffRole.values
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.value),
                          ))
                      .toList(),
                  onChanged: (r) => setLocal(() => selected = r!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reason (audited)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && selected != s.role) {
      try {
        await c.changeRole(
          uid: s.uid,
          newRole: selected.value,
          reason: reasonCtl.text.trim().isEmpty
              ? null
              : reasonCtl.text.trim(),
        );
      } catch (e) {
        Get.snackbar('Failed', e.toString(),
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  Future<void> _resetPassword(StaffListing s) async {
    try {
      final res = await c.resetPassword(uid: s.uid);
      Get.dialog<void>(
        AlertDialog(
          title: const Text('Password reset link generated'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Send to: ${res.email}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          res.resetLink,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy link',
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: res.resetLink));
                          Get.snackbar(
                            'Copied',
                            'Reset link copied',
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Send this link to the staff user out-of-band. The link expires per Identity Platform default (typically 1 hour). Their TOTP enrollment is preserved.',
                  style: TextStyle(color: Colors.amber, fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Get.back<void>(),
              child: const Text('Done'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      Get.snackbar('Failed', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Obx(() => Text(
                    '${c.staff.length} staff users',
                    style: const TextStyle(color: Colors.white60),
                  )),
              const Spacer(),
              Obx(() => FilledButton.icon(
                    onPressed: c.busy.value
                        ? null
                        : () => Get.dialog<void>(const AddStaffModal()),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add staff'),
                  )),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (c.loading.value && c.staff.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (c.error.value != null && c.staff.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(c.error.value!,
                      style: const TextStyle(color: Colors.redAccent)),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: DataTable2(
                columnSpacing: 18,
                horizontalMargin: 12,
                minWidth: 1100,
                columns: const [
                  DataColumn2(label: Text('Email'), size: ColumnSize.L),
                  DataColumn2(label: Text('Name'), size: ColumnSize.L),
                  DataColumn2(label: Text('Role'), size: ColumnSize.S),
                  DataColumn2(label: Text('MFA'), size: ColumnSize.S),
                  DataColumn2(label: Text('Status'), size: ColumnSize.S),
                  DataColumn2(label: Text('Joined'), size: ColumnSize.M),
                  DataColumn2(label: Text('Actions'), size: ColumnSize.L),
                ],
                rows: c.staff
                    .map((s) => DataRow2(cells: [
                          DataCell(Text(s.email,
                              overflow: TextOverflow.ellipsis)),
                          DataCell(Text(s.displayName.isEmpty ? '—' : s.displayName,
                              overflow: TextOverflow.ellipsis)),
                          DataCell(Text(s.role?.value ?? '—')),
                          DataCell(Text(s.mfaEnrolled ? 'Yes' : 'No',
                              style: TextStyle(
                                color: s.mfaEnrolled
                                    ? Colors.greenAccent
                                    : Colors.amber,
                                fontWeight: FontWeight.w600,
                              ))),
                          DataCell(Text(
                            s.disabled ? 'Disabled' : 'Active',
                            style: TextStyle(
                              color: s.disabled
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          )),
                          DataCell(Text(_fmt(s.joinedAt))),
                          DataCell(_RowActions(
                            staff: s,
                            isSelf: s.uid == currentUid,
                            onChangeRole: () => _changeRole(s),
                            onToggleDisabled: () => _confirmDisable(s),
                            onResetPassword: () => _resetPassword(s),
                          )),
                        ]))
                    .toList(),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _RowActions extends StatelessWidget {
  final StaffListing staff;
  final bool isSelf;
  final VoidCallback onChangeRole;
  final VoidCallback onToggleDisabled;
  final VoidCallback onResetPassword;

  const _RowActions({
    required this.staff,
    required this.isSelf,
    required this.onChangeRole,
    required this.onToggleDisabled,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          tooltip: isSelf ? 'Cannot change own role' : 'Change role',
          onPressed: isSelf ? null : onChangeRole,
        ),
        IconButton(
          icon: Icon(
            staff.disabled ? Icons.lock_open : Icons.block,
            size: 18,
            color: staff.disabled ? Colors.greenAccent : Colors.redAccent,
          ),
          tooltip: isSelf
              ? 'Cannot disable yourself'
              : (staff.disabled ? 'Re-enable' : 'Disable'),
          onPressed: isSelf ? null : onToggleDisabled,
        ),
        IconButton(
          icon: const Icon(Icons.lock_reset, size: 18),
          tooltip: 'Reset password',
          onPressed: onResetPassword,
        ),
      ],
    );
  }
}
