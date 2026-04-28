import 'package:flutter/material.dart';

import '../../../core/services/customer_pagers_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';

/// Channels sub-tab — aggregates the org's notification channels into one
/// inventory view. There is no standalone `channels` collection in the
/// customer-app schema, so this widget pieces together:
///   • Team inboxes from `AllTeams.inboxAddress` + aliases
///   • Phone numbers from `escalation_policies.levels[].targets[]`
///   • Per-person emails from the same target list
class PagersChannelsSubTab extends StatelessWidget {
  final String orgId;
  const PagersChannelsSubTab({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerChannelsBundle>(
      future: CustomerPagersService.instance.getChannelsForOrg(orgId),
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
        final bundle = snap.data;
        if (bundle == null || bundle.isEmpty) {
          return const _EmptyBox(
            message: 'No channels configured. Once teams have inboxes or '
                'escalation-policy targets are set, they appear here.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(bundle: bundle),
            const SizedBox(height: AtlasSpace.lg),
            _Section(
              title: 'Email inboxes (per team)',
              subtitle:
                  'These are the addresses customers can email to open an incident. '
                  'Each row is one inbox or alias on a team.',
              child: bundle.inboxes.isEmpty
                  ? const _Inline('No team inboxes configured.')
                  : _InboxList(inboxes: bundle.inboxes),
            ),
            const SizedBox(height: AtlasSpace.lg),
            _Section(
              title: 'Phone numbers (escalation targets)',
              subtitle:
                  'Phones found inside escalation policies. Each appears at a specific '
                  'policy + level. Deduped across policies.',
              child: bundle.phones.isEmpty
                  ? const _Inline('No phone numbers in any escalation policy.')
                  : _PhoneTable(phones: bundle.phones),
            ),
            const SizedBox(height: AtlasSpace.lg),
            _Section(
              title: 'Person emails (escalation targets)',
              subtitle:
                  'Email addresses targeted by escalation policies — distinct from '
                  'team inboxes.',
              child: bundle.personEmails.isEmpty
                  ? const _Inline('No per-person emails in any escalation policy.')
                  : _PersonEmailTable(emails: bundle.personEmails),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final CustomerChannelsBundle bundle;
  const _SummaryRow({required this.bundle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Tile(label: 'Team inboxes', value: '${bundle.inboxes.length}'),
        const SizedBox(width: AtlasSpace.md),
        _Tile(label: 'Phone numbers', value: '${bundle.phones.length}'),
        const SizedBox(width: AtlasSpace.md),
        _Tile(label: 'Person emails', value: '${bundle.personEmails.length}'),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  const _Tile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AtlasSpace.lg),
        decoration: BoxDecoration(
          color: AtlasColors.cardBg,
          border: Border.all(color: AtlasColors.cardBorder),
          borderRadius: BorderRadius.circular(AtlasRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AtlasColors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AtlasColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AtlasSpace.xl, AtlasSpace.lg, AtlasSpace.xl, 4),
            child: Text(title, style: AtlasText.h3),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AtlasSpace.xl, 0, AtlasSpace.xl, AtlasSpace.md),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AtlasColors.textMuted,
                height: 1.5,
              ),
            ),
          ),
          const Divider(height: 1, color: AtlasColors.divider),
          child,
        ],
      ),
    );
  }
}

class _Inline extends StatelessWidget {
  final String text;
  const _Inline(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AtlasSpace.lg),
      child: Text(text, style: AtlasText.smallMuted),
    );
  }
}

class _InboxList extends StatelessWidget {
  final List<CustomerInboxChannel> inboxes;
  const _InboxList({required this.inboxes});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < inboxes.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              border: i == inboxes.length - 1
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AtlasColors.cardBorder),
                    ),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_outlined,
                    size: 16, color: AtlasColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    inboxes[i].email,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: AtlasColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  inboxes[i].teamName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AtlasColors.textSecondary,
                  ),
                ),
                if (inboxes[i].isAlias)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AtlasColors.pillNeutral,
                      borderRadius:
                          BorderRadius.circular(AtlasRadius.round),
                    ),
                    child: const Text(
                      'ALIAS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AtlasColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PhoneTable extends StatelessWidget {
  final List<CustomerPhoneChannel> phones;
  const _PhoneTable({required this.phones});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < phones.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              border: i == phones.length - 1
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AtlasColors.cardBorder),
                    ),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 16, color: AtlasColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SelectableText(
                    phones[i].phone,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: AtlasColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    phones[i].ownerName.isNotEmpty
                        ? phones[i].ownerName
                        : '—',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '${phones[i].teamName} · ${phones[i].policyName} · L${phones[i].level}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AtlasColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PersonEmailTable extends StatelessWidget {
  final List<CustomerPersonEmailChannel> emails;
  const _PersonEmailTable({required this.emails});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < emails.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              border: i == emails.length - 1
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AtlasColors.cardBorder),
                    ),
            ),
            child: Row(
              children: [
                const Icon(Icons.alternate_email,
                    size: 16, color: AtlasColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: SelectableText(
                    emails[i].email,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: AtlasColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    emails[i].ownerName.isNotEmpty
                        ? emails[i].ownerName
                        : '—',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '${emails[i].teamName} · ${emails[i].policyName} · L${emails[i].level}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AtlasColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String message;
  const _EmptyBox({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alt_route,
              size: 28, color: AtlasColors.textMuted),
          const SizedBox(height: 8),
          Text(message, style: AtlasText.smallMuted, textAlign: TextAlign.center),
        ],
      ),
    );
  }
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
        'Failed to load channels: $message',
        style: const TextStyle(color: AtlasColors.danger, fontSize: 12),
      ),
    );
  }
}
