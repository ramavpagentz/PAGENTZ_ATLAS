import 'package:flutter/material.dart';

import '../../../theme/atlas_colors.dart';

/// Visual call-to-action used at the bottom of every snapshot+redirect
/// sub-tab — invites the support engineer to deep-dive in the customer
/// app via staffMode.
class SnapshotRedirectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const SnapshotRedirectCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AtlasSpace.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AtlasColors.accentSoft,
            AtlasColors.accentSoft.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AtlasColors.accentMuted),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AtlasColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AtlasColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AtlasSpace.lg),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.open_in_new, size: 14),
            label: Text(buttonLabel),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
