import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/customer_org_model.dart';
import '../../../core/services/customer_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../utils/routes.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/pii_field.dart';
import '../../../core/models/staff_user_model.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../core/services/customer_admin_service.dart';
import '../../../core/services/ticket_service.dart';
import '../../auth/controller/auth_controller.dart';
import '../../impersonation/widgets/start_impersonation_modal.dart';
import '../../tickets/widgets/create_ticket_dialog.dart';
import '../../tickets/widgets/ticket_chips.dart';
import '../controller/customer_controller.dart';
import '../widgets/activity_timeline_widget.dart';
import '../widgets/admin_action_dialog.dart';

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
            'Activity',
            'Tickets',
            'Subscription',
            if (canSeeSettings) 'Settings',
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
              if (_tab == 0) _OverviewTab(org: org),
              if (_tab == 1) _MembersTab(orgId: org.id),
              if (_tab == 2) _ActivityTab(orgId: org.id),
              if (_tab == 3) _TicketsTab(org: org),
              if (_tab == 4) _SubscriptionTab(org: org),
              if (_tab == 5 && canSeeSettings) _SettingsTab(org: org),
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
                  Text(org.name, style: AtlasText.h2),
                  const SizedBox(height: 2),
                  Text(
                    org.industry ?? 'Organization',
                    style: AtlasText.smallMuted,
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => showCreateTicketDialog(context, org),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New ticket'),
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

class _OverviewTab extends StatelessWidget {
  final CustomerOrg org;
  const _OverviewTab({required this.org});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final isWide = c.maxWidth > 700;
      final overview = _SectionCard(
        title: 'Overview',
        children: [
          _row('Organization', org.name),
          _row('Industry', org.industry ?? '—'),
          _row('Employees', org.numberOfEmployees?.toString() ?? '—'),
          _row(
            'Created',
            org.createdAt != null
                ? DateFormat('MMM d, yyyy').format(org.createdAt!)
                : '—',
          ),
        ],
      );
      final contact = _SectionCard(
        title: 'Contact',
        children: [
          _piiRow(
            'Email',
            PiiField(
              value: org.email,
              type: PiiType.email,
              targetType: 'org',
              targetId: org.id,
              targetDisplay: org.name,
            ),
          ),
          _row('Website', org.website ?? '—'),
        ],
      );
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: overview),
            const SizedBox(width: 16),
            Expanded(child: contact),
          ],
        );
      }
      return Column(children: [overview, const SizedBox(height: 16), contact]);
    });
  }
}

// ─── MEMBERS TAB ────────────────────────────────────────────────────────

class _MembersTab extends StatelessWidget {
  final String orgId;
  const _MembersTab({required this.orgId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: CustomerService.instance.watchOrgMembers(orgId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final members = snap.data ?? const [];
          if (members.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No members in this organization.',
                  style: TextStyle(color: AtlasColors.textMuted, fontSize: 13),
                ),
              ),
            );
          }
          return Column(
            children: members.map((m) {
              final name = (m['displayName'] ?? m['fullName'] ?? m['email'] ?? '—').toString();
              final email = (m['email'] ?? '').toString();
              final role = (m['role'] ?? '').toString();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AtlasColors.cardBorder),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(
                            email,
                            style: const TextStyle(
                              color: AtlasColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (role.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AtlasColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ─── ACTIVITY TAB ───────────────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
  final String orgId;
  const _ActivityTab({required this.orgId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ActivityTimelineWidget(orgId: orgId),
    );
  }
}

// ─── TICKETS TAB ────────────────────────────────────────────────────────

class _TicketsTab extends StatelessWidget {
  final CustomerOrg org;
  const _TicketsTab({required this.org});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Support tickets for this organization',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AtlasColors.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => showCreateTicketDialog(context, org),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('New ticket'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<List<SupportTicket>>(
            stream: TicketService.instance.watchForOrg(org.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final tickets = snap.data ?? const [];
              if (tickets.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 32, color: AtlasColors.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'No tickets yet for this organization.',
                          style: TextStyle(color: AtlasColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: tickets.map((t) => _TicketRow(ticket: t)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final SupportTicket ticket;
  const _TicketRow({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(AtlasRoutes.ticketDetail, arguments: ticket.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AtlasColors.cardBorder)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                ticket.ticketNumber,
                style: const TextStyle(
                  color: AtlasColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ticket.assignedToName != null)
                    Text(
                      'Assigned to ${ticket.assignedToName}',
                      style: const TextStyle(
                        color: AtlasColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PriorityPill(priority: ticket.priority),
            const SizedBox(width: 6),
            StatusPill(status: ticket.status),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: AtlasColors.textMuted),
          ],
        ),
      ),
    );
  }
}

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
                      final uid = (m['uid'] ?? m['id']) as String;
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

class _SubscriptionTab extends StatelessWidget {
  final CustomerOrg org;
  const _SubscriptionTab({required this.org});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Subscription',
      children: [
        _row('Plan', (org.plan ?? 'free').toUpperCase()),
        _row('Status', (org.planStatus ?? 'active').toUpperCase()),
        _row('Members', '${org.memberCount > 0 ? org.memberCount : '—'}'),
        const SizedBox(height: 14),
        const Divider(height: 1, color: AtlasColors.cardBorder),
        const SizedBox(height: 14),
        const Text(
          'Billing is managed externally via the PagentZ web dashboard (Stripe). '
          'Changes here are read-only — to modify a subscription, use Stripe Dashboard.',
          style: TextStyle(color: AtlasColors.textSecondary, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }
}

// ─── SHARED ─────────────────────────────────────────────────────────────

Widget _row(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              color: AtlasColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AtlasColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _piiRow(String label, Widget child) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              color: AtlasColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

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
