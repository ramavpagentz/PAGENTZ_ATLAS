import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/models/staff_user_model.dart';
import '../controller/staff_management_controller.dart';
import '../services/staff_management_service.dart';

class AddStaffModal extends StatefulWidget {
  const AddStaffModal({super.key});

  @override
  State<AddStaffModal> createState() => _AddStaffModalState();
}

class _AddStaffModalState extends State<AddStaffModal> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _nameCtl = TextEditingController();
  final _reasonCtl = TextEditingController();
  StaffRole _role = StaffRole.l1Support;
  String? _error;
  bool _submitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final res = await Get.find<StaffManagementController>().addStaff(
        email: _emailCtl.text.trim().toLowerCase(),
        displayName: _nameCtl.text.trim(),
        role: _role.value,
        reason: _reasonCtl.text.trim(),
      );
      if (!mounted) return;
      Get.back<void>();
      _showTempPasswordDialog(res);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  void _showTempPasswordDialog(CreateStaffResult res) {
    Get.dialog<void>(
      AlertDialog(
        title: const Text('Staff user created'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Account: ${res.email}'),
              const SizedBox(height: 4),
              Text('Role: ${res.role}'),
              const SizedBox(height: 16),
              const Text(
                'Send the temp password below to the new staff user out-of-band (Slack, password manager invite, etc). They will be required to enroll TOTP at first sign-in.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
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
                        res.tempPassword,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy temp password',
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: res.tempPassword));
                        Get.snackbar(
                          'Copied',
                          'Temp password copied to clipboard',
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
                'This password is shown ONCE. If lost, use "Reset password" on the staff row to generate a new reset link.',
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
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add staff user'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'someone@pagentz.com',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  hintText: 'Full name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<StaffRole>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: StaffRole.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.value),
                        ))
                    .toList(),
                onChanged: (r) => setState(() => _role = r ?? StaffRole.l1Support),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonCtl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reason (audited)',
                  hintText: 'e.g. New L1 support hire — onboarding',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 5)
                    ? 'Reason required (min 5 chars) — captured in audit log'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Get.back<void>(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create staff'),
        ),
      ],
    );
  }
}
