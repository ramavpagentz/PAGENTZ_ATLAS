import 'package:flutter/material.dart';
import '../../../core/models/canned_response_model.dart';
import '../../../core/services/canned_response_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';

/// Dropdown picker for canned responses. Shown inside the ticket reply
/// composer. Returns the selected template body.
class CannedResponsePicker extends StatelessWidget {
  final ValueChanged<String> onPicked;
  const CannedResponsePicker({super.key, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CannedResponse>>(
      stream: CannedResponseService.instance.watchAll(),
      builder: (context, snap) {
        final items = snap.data ?? const [];
        return PopupMenuButton<String>(
          tooltip: 'Insert template',
          offset: const Offset(0, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtlasRadius.md),
            side: const BorderSide(color: AtlasColors.cardBorder),
          ),
          color: AtlasColors.cardBg,
          elevation: 8,
          itemBuilder: (_) => items.isEmpty
              ? [
                  const PopupMenuItem<String>(
                    enabled: false,
                    child: Text('No templates yet',
                        style: AtlasText.smallMuted),
                  ),
                ]
              : items
                  .map((t) => PopupMenuItem<String>(
                        value: t.body,
                        child: _TemplateRow(template: t),
                      ))
                  .toList(),
          onSelected: onPicked,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AtlasSpace.sm + 2, vertical: AtlasSpace.xs + 2),
            decoration: BoxDecoration(
              color: AtlasColors.cardBg,
              border: Border.all(color: AtlasColors.cardBorder),
              borderRadius: BorderRadius.circular(AtlasRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.description_outlined,
                    size: 14, color: AtlasColors.textSecondary),
                SizedBox(width: AtlasSpace.xs + 2),
                Text(
                  'Templates',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AtlasColors.textSecondary,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down,
                    size: 14, color: AtlasColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TemplateRow extends StatelessWidget {
  final CannedResponse template;
  const _TemplateRow({required this.template});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            template.title,
            style: AtlasText.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            template.body,
            style: AtlasText.tiny,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
