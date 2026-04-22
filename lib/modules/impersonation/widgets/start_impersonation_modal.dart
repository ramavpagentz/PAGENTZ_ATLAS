import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/customer_org_model.dart';
import '../../../core/models/impersonation_session_model.dart';
import '../../../core/models/staff_user_model.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/impersonation_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../auth/controller/auth_controller.dart';

/// Shows a dialog that lets the staff user start an impersonation session.
Future<void> showStartImpersonationModal(BuildContext context, CustomerOrg org) {
  return showDialog(
    context: context,
    builder: (_) => _ImpersonationDialog(org: org),
  );
}

class _ImpersonationDialog extends StatefulWidget {
  final CustomerOrg org;
  const _ImpersonationDialog({required this.org});

  @override
  State<_ImpersonationDialog> createState() => _ImpersonationDialogState();
}

class _ImpersonationDialogState extends State<_ImpersonationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String? _selectedUid;
  ImpersonationMode _mode = ImpersonationMode.readOnly;
  int _durationMinutes = 60;
  bool _isStarting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final staff = auth.currentStaff.value;
    final canWriteMode = staff != null && staff.role.isAtLeast(StaffRole.engineer);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AtlasColors.dangerSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_outline,
                        color: AtlasColors.danger,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start impersonation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AtlasColors.textPrimary,
                            ),
                          ),
                          Text(
                            widget.org.name,
                            style: const TextStyle(
                              color: AtlasColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isStarting ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AtlasColors.warningSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AtlasColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, color: AtlasColors.warning, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This action will be visible to the customer and recorded in the audit log forever. '
                          'Provide a clear reason and use read-only mode unless you must write.',
                          style: TextStyle(
                            color: AtlasColors.warning,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // User picker
                const _Label('User to impersonate'),
                const SizedBox(height: 6),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: CustomerService.instance.watchOrgMembers(widget.org.id),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final members = snap.data ?? const [];
                    if (members.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No members in this organization to impersonate.',
                          style: TextStyle(color: AtlasColors.textSecondary, fontSize: 12),
                        ),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedUid,
                      isExpanded: true,
                      items: members.map((m) {
                        final uid = m['uid'] as String? ?? m['id'] as String;
                        final email = (m['email'] ?? uid).toString();
                        final name = (m['displayName'] ?? m['fullName'] ?? email).toString();
                        return DropdownMenuItem(
                          value: uid,
                          child: Text(
                            '$name · $email',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedUid = v),
                      validator: (v) =>
                          v == null ? 'Pick a user to impersonate' : null,
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Reason
                const _Label('Reason (required, min 10 chars)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Customer reported escalation policy not firing — ticket T-A4F2C',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'Reason must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Mode toggle
                const _Label('Mode'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: 'Read-only',
                        sublabel: 'Recommended',
                        icon: Icons.visibility_outlined,
                        selected: _mode == ImpersonationMode.readOnly,
                        onTap: () => setState(() => _mode = ImpersonationMode.readOnly),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ModeButton(
                        label: 'Read-write',
                        sublabel: canWriteMode ? 'Engineer+' : 'Locked',
                        icon: Icons.edit_outlined,
                        selected: _mode == ImpersonationMode.readWrite,
                        disabled: !canWriteMode,
                        onTap: !canWriteMode
                            ? null
                            : () => setState(() => _mode = ImpersonationMode.readWrite),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Duration
                const _Label('Session length'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [15, 30, 60].map((m) {
                    final sel = _durationMinutes == m;
                    return ChoiceChip(
                      label: Text(m == 60 ? '1 hr' : '$m min'),
                      selected: sel,
                      selectedColor: AtlasColors.accent,
                      labelStyle: TextStyle(
                        color: sel ? Colors.white : AtlasColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _durationMinutes = m),
                    );
                  }).toList(),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AtlasColors.dangerSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AtlasColors.danger, fontSize: 12),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isStarting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isStarting ? null : _start,
                        icon: _isStarting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.open_in_new, size: 16),
                        label: Text(_isStarting ? 'Starting…' : 'Start session'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _start() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isStarting = true;
      _error = null;
    });

    final result = await ImpersonationService.instance.startSession(
      orgId: widget.org.id,
      targetUid: _selectedUid!,
      reason: _reasonController.text.trim(),
      mode: _mode,
      durationMinutes: _durationMinutes,
    );

    if (!mounted) return;
    setState(() => _isStarting = false);
    if (result.ok) {
      Navigator.of(context).pop();
      Get.snackbar(
        'Impersonation started',
        'A new tab opened to the customer app. The session is logged.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AtlasColors.accentSoft,
        colorText: AtlasColors.accentHover,
        margin: const EdgeInsets.all(16),
      );
    } else {
      setState(() => _error = result.errorMessage);
    }
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AtlasColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _ModeButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.selected,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AtlasColors.accentSoft : AtlasColors.cardBg,
            border: Border.all(
              color: selected ? AtlasColors.accent : AtlasColors.cardBorder,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AtlasColors.accent : AtlasColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: selected ? AtlasColors.accent : AtlasColors.textPrimary,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: const TextStyle(
                        color: AtlasColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
