import 'package:flutter/material.dart';

import '../../../core/services/audit_log_service.dart';
import '../../../theme/atlas_colors.dart';

/// Modal that lets staff add an internal note about a customer org.
/// The note is written to `staff_audit_logs` with action
/// `ADDED_INTERNAL_NOTE` and becomes visible to other staff via the
/// Activity tab's audit feed and the staff audit log screen.
///
/// Until a dedicated `org_staff_notes` collection exists, this is the
/// canonical place for "internal note about this org".
Future<void> showAddInternalNoteDialog({
  required BuildContext context,
  required String orgId,
  required String orgName,
}) async {
  final controller = TextEditingController();
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Add internal note · $orgName'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visible to other staff via the audit log. Use this to record '
              'context that\'s not customer-facing — e.g. a workaround, a '
              'pending follow-up, or a billing nuance.',
              style: TextStyle(
                fontSize: 13,
                color: AtlasColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 6,
              minLines: 4,
              decoration: const InputDecoration(
                hintText: 'Customer reported X. Tried Y. Suspect Z.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final text = controller.text.trim();
            if (text.length < 5) return;
            await AuditLogService.instance.log(
              action: 'ADDED_INTERNAL_NOTE',
              targetType: 'org',
              targetId: orgId,
              targetDisplay: orgName,
              changes: {
                'note': text,
                'preview': text.length > 80
                    ? '${text.substring(0, 80)}…'
                    : text,
              },
            );
            if (context.mounted) Navigator.of(context).pop(true);
          },
          child: const Text('Save note'),
        ),
      ],
    ),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Internal note saved to audit log.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
