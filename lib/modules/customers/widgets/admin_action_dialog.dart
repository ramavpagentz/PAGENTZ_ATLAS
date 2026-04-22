import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/customer_admin_service.dart';
import '../../../theme/atlas_colors.dart';

enum AdminAction {
  resetPassword('Reset password', Icons.password, AtlasColors.info,
      'Sends a Firebase password reset email to the user.'),
  revokeSessions('Force sign-out', Icons.logout, AtlasColors.warning,
      'Revokes all active sessions. The user must sign in again on all devices.'),
  disableOrg('Disable organization', Icons.block, AtlasColors.danger,
      'Marks the organization as disabled. Members cannot access the app until re-enabled.'),
  enableOrg('Re-enable organization', Icons.check_circle_outline, AtlasColors.success,
      'Restores access for the organization\'s members.');

  final String label;
  final IconData icon;
  final Color color;
  final String description;
  const AdminAction(this.label, this.icon, this.color, this.description);
}

/// Generic confirm-with-reason dialog for the 3 customer-admin actions.
/// Returns true if the action succeeded.
Future<bool> showAdminActionDialog({
  required BuildContext context,
  required AdminAction action,
  required String targetLabel,
  required Future<AdminActionResult> Function(String reason) onConfirm,
}) async {
  final controller = TextEditingController();
  bool busy = false;
  String? error;

  final result = await showDialog<bool>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: action.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(action.icon, color: action.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.label,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AtlasColors.textPrimary,
                            ),
                          ),
                          Text(
                            targetLabel,
                            style: const TextStyle(
                              color: AtlasColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: busy ? null : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  action.description,
                  style: const TextStyle(color: AtlasColors.textSecondary, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Reason (required, 5+ chars)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AtlasColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Customer reported account compromise — ticket T-A4F2C',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AtlasColors.dangerSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      error!,
                      style: const TextStyle(color: AtlasColors.danger, fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: busy
                            ? null
                            : () async {
                                final reason = controller.text.trim();
                                if (reason.length < 5) {
                                  setState(() => error = 'Reason must be at least 5 characters.');
                                  return;
                                }
                                setState(() {
                                  busy = true;
                                  error = null;
                                });
                                final result = await onConfirm(reason);
                                if (!result.ok) {
                                  setState(() {
                                    busy = false;
                                    error = result.errorMessage ?? 'Action failed.';
                                  });
                                  return;
                                }
                                if (context.mounted) Navigator.of(context).pop(true);
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: action.color),
                        icon: busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(action.icon, size: 14),
                        label: Text(busy ? 'Working…' : 'Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  if (result == true) {
    Get.snackbar(
      'Done',
      '${action.label} completed.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: action.color.withValues(alpha: 0.15),
      colorText: action.color,
      margin: const EdgeInsets.all(16),
    );
  }
  return result == true;
}
