import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';

/// Read-only mirror of the customer's own settings — pulls every doc under
/// `organizations/{orgId}/settings` and renders it as a key/value card.
///
/// Distinct from the existing `_SettingsTab` ("Admin actions") which is
/// staff-action-driven (reset password / disable org). This tab is
/// visible to all staff and shows only what the customer has configured.
class SettingsTab extends StatelessWidget {
  final String orgId;
  const SettingsTab({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .collection('settings')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return _ErrorBox(message: snap.error.toString());
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return _empty();
        }
        // Stable order: well-known doc IDs first, then alphabetical.
        const order = [
          'modules',
          'severity_rules',
          'integrations',
          'pagers',
          'alerts',
          'escalation_overrides',
          'assets',
          'ipam',
        ];
        docs.sort((a, b) {
          final ai = order.indexOf(a.id);
          final bi = order.indexOf(b.id);
          if (ai != -1 && bi != -1) return ai.compareTo(bi);
          if (ai != -1) return -1;
          if (bi != -1) return 1;
          return a.id.compareTo(b.id);
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Read-only mirror of the customer\'s own org settings. '
                'To change anything, the customer must edit it themselves '
                'or you can use the Admin actions tab.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AtlasColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            for (final d in docs)
              Padding(
                padding: const EdgeInsets.only(bottom: AtlasSpace.md),
                child: _SettingCard(
                  docId: d.id,
                  data: d.data(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_suggest_outlined,
              size: 28, color: AtlasColors.textMuted),
          SizedBox(height: 8),
          Text('No settings configured for this organization yet.',
              style: AtlasText.smallMuted),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _SettingCard({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Container(
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
        boxShadow: AtlasElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AtlasSpace.xl, AtlasSpace.lg, AtlasSpace.xl, AtlasSpace.md),
            child: Row(
              children: [
                Expanded(child: Text(_humanize(docId), style: AtlasText.h3)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AtlasColors.pillNeutral,
                    borderRadius: BorderRadius.circular(AtlasRadius.round),
                  ),
                  child: Text(
                    docId,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AtlasColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AtlasColors.divider),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AtlasSpace.lg),
              child: Text('(empty document)', style: AtlasText.smallMuted),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AtlasSpace.xl, vertical: AtlasSpace.sm),
              child: Column(
                children: entries
                    .map((e) => _kvRow(e.key, e.value))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

String _humanize(String s) {
  // "severity_rules" → "Severity rules"
  if (s.isEmpty) return s;
  final parts = s.split(RegExp(r'[_\s]+'));
  return parts
      .map((p) => p.isEmpty
          ? p
          : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
      .join(' ');
}

Widget _kvRow(String label, dynamic value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AtlasColors.textMuted,
            ),
          ),
        ),
        Expanded(child: _renderValue(value)),
      ],
    ),
  );
}

Widget _renderValue(dynamic v) {
  if (v == null) {
    return const Text('—',
        style: TextStyle(fontSize: 13, color: AtlasColors.textMuted));
  }
  if (v is bool) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (v ? AtlasColors.success : AtlasColors.textMuted)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AtlasRadius.round),
      ),
      constraints: const BoxConstraints(maxWidth: 70),
      alignment: Alignment.center,
      child: Text(
        v ? 'On' : 'Off',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: v ? AtlasColors.success : AtlasColors.textMuted,
        ),
      ),
    );
  }
  if (v is num || v is String) {
    return SelectableText(
      v.toString(),
      style: const TextStyle(fontSize: 13, color: AtlasColors.textPrimary),
    );
  }
  if (v is Timestamp) {
    return Text(
      DateFormat('yyyy-MM-dd HH:mm').format(v.toDate()),
      style: const TextStyle(fontSize: 13, color: AtlasColors.textPrimary),
    );
  }
  if (v is List) {
    if (v.isEmpty) {
      return const Text('(empty list)',
          style: TextStyle(fontSize: 12, color: AtlasColors.textMuted));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: v.map((e) => _renderValue(e)).toList(),
    );
  }
  if (v is Map) {
    final entries = v.entries.toList();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AtlasColors.tableHeaderBg,
        borderRadius: BorderRadius.circular(AtlasRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    e.key.toString(),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AtlasColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(child: _renderValue(e.value)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  // Fallback
  return Text(
    v.toString(),
    style: const TextStyle(fontSize: 12.5, color: AtlasColors.textPrimary),
  );
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AtlasColors.dangerSoft,
        border: Border.all(color: AtlasColors.danger),
        borderRadius: BorderRadius.circular(AtlasRadius.md),
      ),
      child: Text(
        'Failed to load settings: $message',
        style: const TextStyle(color: AtlasColors.danger, fontSize: 12),
      ),
    );
  }
}
