import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/customer_org_model.dart';
import '../../../core/services/customer_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../utils/routes.dart';
import '../../../widgets/app_shell.dart';
import '../../../core/models/staff_user_model.dart';
import '../../../core/services/customer_admin_service.dart';
import '../../auth/controller/auth_controller.dart';
import '../../impersonation/widgets/start_impersonation_modal.dart';
import '../../tickets/widgets/create_ticket_dialog.dart';
import '../controller/customer_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/audit_log_service.dart';
import '../widgets/activity_tab.dart';
import '../widgets/add_internal_note_dialog.dart';
import '../widgets/admin_action_dialog.dart';
import '../widgets/health_tab.dart';
import '../widgets/integrations_tab.dart';
import '../widgets/members_tab.dart';
import '../widgets/org_alert_banner.dart';
import '../widgets/overview_tab.dart' as overview;
import '../widgets/pagers_tab.dart';
import '../widgets/settings_tab.dart';
import '../widgets/subscription_tab.dart' as cust_sub;
import '../widgets/support_tab.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CustomerController>();

    return AppShell(
      currentRoute: AtlasRoutes.customerDetail,
      pageTitle: 'Customer detail',
      pageSubtitle: 'View, support, or impersonate this organization.',
      child: Obx(() {
        if (controller.selectedLoading.value) {
          return const Padding(
            padding: EdgeInsets.all(AtlasSpace.huge),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final org = controller.selected.value;
        if (org == null) return _NotFound();
        return _DetailBody(org: org);
      }),
    );
  }
}

class _NotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AtlasSpace.huge),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AtlasColors.pillNeutral,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.business_outlined,
                size: 26, color: AtlasColors.textMuted),
          ),
          const SizedBox(height: AtlasSpace.md),
          const Text('Customer not found',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AtlasColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Try going back to the customers list.',
              style: AtlasText.smallMuted),
          const SizedBox(height: AtlasSpace.lg),
          OutlinedButton.icon(
            onPressed: () => Get.offAllNamed(AtlasRoutes.customers),
            icon: const Icon(Icons.arrow_back, size: 14),
            label: const Text('All customers'),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatefulWidget {
  final CustomerOrg org;
  const _DetailBody({required this.org});

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final org = widget.org;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        InkWell(
          onTap: () => Get.offAllNamed(AtlasRoutes.customers),
          borderRadius: BorderRadius.circular(AtlasRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AtlasSpace.sm, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.arrow_back, size: 14, color: AtlasColors.textSecondary),
                SizedBox(width: AtlasSpace.xs + 2),
                Text('Customers',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AtlasColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AtlasSpace.md),

        // Alert banner (active P1 / unacked) — renders nothing when healthy.
        OrgAlertBanner(orgId: org.id),

        // Header card
        _HeaderCard(org: org),
        const SizedBox(height: AtlasSpace.xl),

        // Tabs
        Obx(() {
          final me = Get.find<AuthController>().currentStaff.value;
          final canSeeSettings = me != null && me.role.isAtLeast(StaffRole.admin);
          final tabs = <String>[
            'Overview',
            'Members',
            'Pagers',
            'Health ⭐',
            'Integrations',
            'Activity',
            'Support',
            'Subscription',
            'Settings',
            if (canSeeSettings) 'Admin',
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TabBar(
                tabs: tabs,
                selectedIndex: _tab >= tabs.length ? 0 : _tab,
                onSelect: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: 16),

              // Tab content
              if (_tab == 0) overview.OverviewTab(org: org),
              if (_tab == 1) MembersTab(orgId: org.id),
              if (_tab == 2) PagersTab(org: org),
              if (_tab == 3) HealthTab(orgId: org.id),
              if (_tab == 4) IntegrationsTab(orgId: org.id, orgName: org.name),
              if (_tab == 5) ActivityTab(orgId: org.id, orgName: org.name),
              if (_tab == 6) SupportTab(org: org),
              if (_tab == 7) cust_sub.SubscriptionTab(org: org),
              if (_tab == 8) SettingsTab(orgId: org.id),
              if (_tab == 9 && canSeeSettings) _SettingsTab(org: org),
            ],
          );
        }),
      ],
    );
  }
}

// ─── HEADER ─────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final CustomerOrg org;
  const _HeaderCard({required this.org});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AtlasSpace.xl),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
        boxShadow: AtlasElevation.sm,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AtlasSpace.lg,
        runSpacing: AtlasSpace.md,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AtlasColors.accent, AtlasColors.accentActive],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AtlasRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: AtlasColors.accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.business_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: AtlasSpace.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(org.name, style: AtlasText.h2),
                      const SizedBox(width: 10),
                      _PlanPill(plan: org.plan),
                      if (org.disabled) ...[
                        const SizedBox(width: 6),
                        const _DangerPill(label: 'DISABLED'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _headerSubtitle(org),
                    style: AtlasText.smallMuted,
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => showCreateTicketDialog(context, org),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New ticket'),
              ),
              OutlinedButton.icon(
                onPressed: () => showAddInternalNoteDialog(
                  context: context,
                  orgId: org.id,
                  orgName: org.name,
                ),
                icon: const Icon(Icons.sticky_note_2_outlined, size: 16),
                label: const Text('Add internal note'),
              ),
              if ((org.email ?? '').isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _startTeamsCall(org),
                  icon: const Icon(Icons.videocam_outlined, size: 16),
                  label: const Text('Start Teams call'),
                ),
              ElevatedButton.icon(
                onPressed: () => showStartImpersonationModal(context, org),
                icon: const Icon(Icons.person_outline, size: 16),
                label: const Text('Impersonate'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _headerSubtitle(CustomerOrg org) {
  final parts = <String>[];
  if ((org.industry ?? '').isNotEmpty) parts.add(org.industry!);
  if (org.memberCount > 0) {
    parts.add('${org.memberCount} member${org.memberCount == 1 ? "" : "s"}');
  }
  if (org.createdAt != null) {
    final fmt = DateFormat('MMM d, yyyy');
    final age = _ageInMonths(org.createdAt!);
    parts.add('Customer since ${fmt.format(org.createdAt!)}'
        '${age.isEmpty ? "" : " ($age)"}');
  }
  return parts.isEmpty ? 'Organization' : parts.join(' · ');
}

String _ageInMonths(DateTime when) {
  final now = DateTime.now();
  final months = (now.year - when.year) * 12 + (now.month - when.month);
  if (months < 1) return '< 1 month';
  if (months < 12) return '$months months';
  final years = months ~/ 12;
  return years == 1 ? '1 year' : '$years years';
}

class _PlanPill extends StatelessWidget {
  final String? plan;
  const _PlanPill({required this.plan});
  @override
  Widget build(BuildContext context) {
    final p = (plan ?? 'free').toLowerCase();
    final (color, label) = switch (p) {
      'premium' => (const Color(0xFF7C3AED), 'PREMIUM'),
      'plus' => (AtlasColors.info, 'PLUS'),
      'enterprise' => (const Color(0xFF7C3AED), 'ENTERPRISE'),
      _ => (AtlasColors.textMuted, 'FREE'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AtlasRadius.round),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _DangerPill extends StatelessWidget {
  final String label;
  const _DangerPill({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AtlasColors.dangerSoft,
        borderRadius: BorderRadius.circular(AtlasRadius.round),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AtlasColors.danger,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Open a Microsoft Teams call to the customer's primary email. Audit-logs
/// the action so we know which staff initiated which call.
Future<void> _startTeamsCall(CustomerOrg org) async {
  final email = (org.email ?? '').trim();
  if (email.isEmpty) return;
  AuditLogService.instance.log(
    action: 'STARTED_TEAMS_CALL',
    targetType: 'org',
    targetId: org.id,
    targetDisplay: org.name,
    changes: {'targetEmail': email},
  );
  final url = Uri.parse(
    'https://teams.microsoft.com/l/call/0/0?users=${Uri.encodeComponent(email)}',
  );
  await launchUrl(url, mode: LaunchMode.externalApplication);
}

// ─── TAB BAR ────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _TabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AtlasColors.divider)),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSel = i == selectedIndex;
          return _TabItem(
            label: tabs[i],
            selected: isSel,
            onTap: () => onSelect(i),
          );
        }),
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(
              horizontal: AtlasSpace.md + 2, vertical: AtlasSpace.md),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.selected
                    ? AtlasColors.accent
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: widget.selected
                  ? AtlasColors.textPrimary
                  : (_hover
                      ? AtlasColors.textPrimary
                      : AtlasColors.textSecondary),
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── OVERVIEW TAB ───────────────────────────────────────────────────────
//
// Overview content lives in `widgets/overview_tab.dart`. It adds 3 stat
// tiles (members / open incidents / health score) and an auto-detected
// onboarding-progress card on top of the existing org-detail/contact cards.

// ─── MEMBERS TAB ────────────────────────────────────────────────────────
//
// The Members tab content lives in `widgets/members_tab.dart` (see
// `MembersTab`). It surfaces status / role / last-active / invited-at.

// ─── ACTIVITY TAB ───────────────────────────────────────────────────────
//
// The Activity tab content lives in `widgets/activity_tab.dart`
// (`ActivityTab`). It adds filter chips, CSV export, and a tap-to-open
// detail dialog over the existing `ActivityTimelineWidget` data source.

// ─── TICKETS TAB ────────────────────────────────────────────────────────
//
// Tickets + Internal notes content lives in `widgets/support_tab.dart`.

// ─── SETTINGS TAB (Admin+ only) ─────────────────────────────────────────

class _SettingsTab extends StatelessWidget {
  final CustomerOrg org;
  const _SettingsTab({required this.org});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Admin actions',
      children: [
        const SizedBox(height: 6),
        const Text(
          'These actions are audit-logged and require a written reason.',
          style: TextStyle(color: AtlasColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),
        _ActionTile(
          icon: Icons.password,
          color: AtlasColors.info,
          title: 'Reset customer password',
          description:
              'Sends a Firebase password reset email to a member. Common for compromised accounts.',
          onTap: () => _pickMemberAndAction(
            context: context,
            org: org,
            action: AdminAction.resetPassword,
          ),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.logout,
          color: AtlasColors.warning,
          title: 'Force sign-out',
          description:
              'Revokes all sessions for a member. They\'ll need to sign in again on every device.',
          onTap: () => _pickMemberAndAction(
            context: context,
            org: org,
            action: AdminAction.revokeSessions,
          ),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: org.disabled ? Icons.check_circle_outline : Icons.block,
          color: org.disabled ? AtlasColors.success : AtlasColors.danger,
          title: org.disabled ? 'Re-enable organization' : 'Disable organization',
          description: org.disabled
              ? 'Restore access to the organization for all its members.'
              : 'Block the organization from accessing PagentZ. Use for severe TOS violations.',
          onTap: () async {
            final action = org.disabled ? AdminAction.enableOrg : AdminAction.disableOrg;
            await showAdminActionDialog(
              context: context,
              action: action,
              targetLabel: org.name,
              onConfirm: (reason) => CustomerAdminService.instance.setOrgDisabled(
                orgId: org.id,
                orgName: org.name,
                disabled: !org.disabled,
                reason: reason,
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _pickMemberAndAction({
    required BuildContext context,
    required CustomerOrg org,
    required AdminAction action,
  }) async {
    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _MemberPickerDialog(orgId: org.id, action: action),
    );
    if (picked == null || !context.mounted) return;

    final uid = picked['uid'] as String;
    final email = (picked['email'] ?? '') as String;

    await showAdminActionDialog(
      context: context,
      action: action,
      targetLabel: email,
      onConfirm: (reason) async {
        if (action == AdminAction.resetPassword) {
          return CustomerAdminService.instance.sendPasswordReset(
            userUid: uid, userEmail: email, reason: reason,
          );
        }
        if (action == AdminAction.revokeSessions) {
          return CustomerAdminService.instance.revokeSessions(
            userUid: uid, userEmail: email, reason: reason,
          );
        }
        return const AdminActionResult.failed('Unsupported action');
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AtlasColors.cardBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AtlasColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AtlasColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: AtlasColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _MemberPickerDialog extends StatelessWidget {
  final String orgId;
  final AdminAction action;
  const _MemberPickerDialog({required this.orgId, required this.action});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 540),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pick a member · ${action.label}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AtlasColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AtlasColors.cardBorder),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: CustomerService.instance.watchOrgMembers(orgId),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final members = snap.data ?? const [];
                  if (members.isEmpty) {
                    return const Center(
                      child: Text(
                        'No members in this organization.',
                        style: TextStyle(color: AtlasColors.textMuted, fontSize: 13),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: members.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AtlasColors.cardBorder),
                    itemBuilder: (_, i) {
                      final m = members[i];
                      final email = (m['email'] ?? '') as String;
                      final name = (m['displayName'] ?? m['fullName'] ?? email) as String;
                      // Canonical field name in customer-app member docs is
                      // `userId` (see PAGENTZDEV `org_member_model.dart`).
                      // Don't fall back to `m['id']` — that's the doc id and,
                      // even though the customer app currently happens to use
                      // uid as doc id, relying on that conflates two
                      // identities and breaks if the schema ever changes.
                      final uid = (m['userId'] ?? '') as String;
                      assert(uid.isNotEmpty, 'member doc missing userId field');
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AtlasColors.accentSoft,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: AtlasColors.accent,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontSize: 13)),
                        subtitle: Text(email, style: const TextStyle(fontSize: 11)),
                        trailing: const Icon(Icons.chevron_right,
                            size: 16, color: AtlasColors.textMuted),
                        onTap: () => Navigator.of(context).pop({'uid': uid, 'email': email}),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SUBSCRIPTION TAB ───────────────────────────────────────────────────
//
// Subscription tab content lives in `widgets/subscription_tab.dart`.
// It reads the `subscription` map field on the org doc and links to the
// Stripe dashboard.

// ─── SHARED ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(AtlasSpace.xl, AtlasSpace.lg,
                AtlasSpace.xl, AtlasSpace.md),
            child: Text(title, style: AtlasText.h3),
          ),
          const Divider(height: 1, color: AtlasColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AtlasSpace.xl, vertical: AtlasSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
