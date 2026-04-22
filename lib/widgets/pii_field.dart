import 'package:flutter/material.dart';
import '../core/services/audit_log_service.dart';
import '../theme/atlas_colors.dart';

enum PiiType { email, phone, generic }

/// Displays a piece of PII (email, phone, etc.) masked by default.
/// Staff must click "Reveal" and enter a reason. The reveal is audit-logged.
///
/// Example:
///   PiiField(
///     value: org.email,
///     type: PiiType.email,
///     targetType: 'org',
///     targetId: org.id,
///     targetDisplay: org.name,
///   )
class PiiField extends StatefulWidget {
  final String? value;
  final PiiType type;
  final String targetType;
  final String targetId;
  final String? targetDisplay;
  final TextStyle? textStyle;

  const PiiField({
    super.key,
    required this.value,
    required this.type,
    required this.targetType,
    required this.targetId,
    this.targetDisplay,
    this.textStyle,
  });

  @override
  State<PiiField> createState() => _PiiFieldState();
}

class _PiiFieldState extends State<PiiField> {
  bool _revealed = false;

  String _mask(String s) {
    if (s.isEmpty) return '—';
    if (widget.type == PiiType.email && s.contains('@')) {
      final parts = s.split('@');
      final local = parts[0];
      final domain = parts[1];
      final visible = local.length <= 2 ? local[0] : local.substring(0, 2);
      return '$visible${'•' * 5}@$domain';
    }
    if (widget.type == PiiType.phone) {
      if (s.length <= 4) return '${'•' * (s.length - 2)}${s.substring(s.length - 2)}';
      return '${'•' * (s.length - 4)}${s.substring(s.length - 4)}';
    }
    if (s.length <= 4) return '••••';
    return '${'•' * (s.length - 3)}${s.substring(s.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value ?? '';
    if (value.isEmpty) {
      return Text(
        '—',
        style: widget.textStyle ??
            const TextStyle(color: AtlasColors.textMuted, fontSize: 13),
      );
    }

    final display = _revealed ? value : _mask(value);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SelectableText(
            display,
            style: widget.textStyle ??
                const TextStyle(
                  color: AtlasColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
          ),
        ),
        const SizedBox(width: 6),
        if (!_revealed)
          InkWell(
            onTap: () => _promptReveal(context),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                'Reveal',
                style: TextStyle(
                  color: AtlasColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
        else
          InkWell(
            onTap: () => setState(() => _revealed = false),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Icon(Icons.visibility_off_outlined,
                  size: 14, color: AtlasColors.textMuted),
            ),
          ),
      ],
    );
  }

  Future<void> _promptReveal(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reveal PII'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why are you revealing this customer\'s PII? '
              'This action will be recorded in the audit log forever.',
              style: TextStyle(fontSize: 13, color: AtlasColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Verifying identity for ticket T-A4F2C',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final r = controller.text.trim();
              if (r.length < 5) return;
              Navigator.of(context).pop(r);
            },
            child: const Text('Reveal'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    AuditLogService.instance.log(
      action: 'VIEWED_PII',
      targetType: widget.targetType,
      targetId: widget.targetId,
      targetDisplay: widget.targetDisplay,
      reason: reason,
    );
    setState(() => _revealed = true);
  }
}
