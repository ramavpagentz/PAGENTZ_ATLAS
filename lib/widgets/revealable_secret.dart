import 'dart:async';
import 'package:flutter/material.dart';

import '../core/services/audit_log_service.dart';
import '../theme/atlas_colors.dart';

/// Generic reveal-with-reason field for sensitive values like API keys
/// and webhook secrets. Mirrors the `PiiField` pattern but logs as
/// `REVEALED_API_KEY` instead of `VIEWED_PII`, and auto-re-masks after
/// 30 seconds so a secret left on screen doesn't sit there indefinitely.
class RevealableSecret extends StatefulWidget {
  final String? value;
  final String label;
  final String targetType;
  final String targetId;
  final String? targetDisplay;
  final Duration revealDuration;

  const RevealableSecret({
    super.key,
    required this.value,
    required this.label,
    required this.targetType,
    required this.targetId,
    this.targetDisplay,
    this.revealDuration = const Duration(seconds: 30),
  });

  @override
  State<RevealableSecret> createState() => _RevealableSecretState();
}

class _RevealableSecretState extends State<RevealableSecret> {
  bool _revealed = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _mask(String s) {
    if (s.isEmpty) return '—';
    if (s.length <= 8) return '•' * s.length;
    return '${'•' * 12}${s.substring(s.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value ?? '';
    if (value.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(color: AtlasColors.textMuted, fontSize: 13),
      );
    }
    final display = _revealed ? value : _mask(value);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SelectableText(
            display,
            style: const TextStyle(
              color: AtlasColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 8),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'auto-hides',
                  style: TextStyle(
                    fontSize: 10,
                    color: AtlasColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  _timer?.cancel();
                  setState(() => _revealed = false);
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Icon(Icons.visibility_off_outlined,
                      size: 14, color: AtlasColors.textMuted),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _promptReveal(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reveal ${widget.label}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why are you revealing this secret? '
              'This action will be recorded in the audit log forever, '
              'and the value will auto-hide after 30 seconds.',
              style: TextStyle(fontSize: 13, color: AtlasColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Verifying webhook signature for ticket T-A4F2C',
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
              if (r.length < 10) return; // matches spec: ≥10 chars
              Navigator.of(context).pop(r);
            },
            child: const Text('Reveal'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    AuditLogService.instance.log(
      action: 'REVEALED_API_KEY',
      targetType: widget.targetType,
      targetId: widget.targetId,
      targetDisplay: widget.targetDisplay,
      reason: reason,
      changes: {'label': widget.label},
    );

    if (!mounted) return;
    setState(() => _revealed = true);
    _timer?.cancel();
    _timer = Timer(widget.revealDuration, () {
      if (mounted) setState(() => _revealed = false);
    });
  }
}
