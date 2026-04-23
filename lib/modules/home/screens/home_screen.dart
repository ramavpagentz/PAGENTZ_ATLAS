import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/customer_org_model.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../utils/routes.dart';
import '../../../widgets/app_shell.dart';
import '../../auth/controller/auth_controller.dart';
import '../../tickets/widgets/ticket_chips.dart';
import '../controller/home_controller.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AtlasRoutes.home,
      pageTitle: _greeting(),
      pageSubtitle: 'Atlas at a glance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI grid
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 1100
                  ? 4
                  : c.maxWidth > 700
                      ? 2
                      : 1;
              return Obx(() {
                final total = controller.totalCustomers;
                final newWeek = controller.newThisWeek;
                final active = controller.activeThisMonth;
                final open = controller.openTicketCount;
                final urgent = controller.urgentTicketCount;
                final healthy = controller.systemHealthy;
                return GridView.count(
                  crossAxisCount: cols,
                  mainAxisSpacing: AtlasSpace.lg,
                  crossAxisSpacing: AtlasSpace.lg,
                  shrinkWrap: true,
                  childAspectRatio: cols == 1 ? 4 : 2.4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _KpiCard(
                      label: 'Total customers',
                      value: '$total',
                      delta: newWeek > 0 ? '+$newWeek this week' : null,
                      deltaPositive: true,
                      icon: Icons.business_rounded,
                    ),
                    _KpiCard(
                      label: 'Active this month',
                      value: '$active',
                      delta: total > 0
                          ? '${(active * 100 / total).toStringAsFixed(0)}%'
                          : null,
                      icon: Icons.bolt_rounded,
                    ),
                    _KpiCard(
                      label: 'Open tickets',
                      value: '$open',
                      delta: urgent > 0 ? '$urgent urgent' : null,
                      deltaWarning: urgent > 0,
                      icon: Icons.inbox_rounded,
                    ),
                    _KpiCard(
                      label: 'System health',
                      value: healthy ? 'Operational' : 'Checking',
                      delta: healthy ? 'All systems normal' : null,
                      deltaPositive: healthy,
                      icon: healthy
                          ? Icons.check_circle_rounded
                          : Icons.sync_rounded,
                    ),
                  ],
                );
              });
            },
          ),

          const SizedBox(height: AtlasSpace.xxl),

          // Two-column dashboard
          LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth > 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _RecentSignupsCard(controller: controller)),
                    const SizedBox(width: AtlasSpace.lg),
                    Expanded(child: _UrgentTicketsCard(controller: controller)),
                  ],
                );
              }
              return Column(
                children: [
                  _RecentSignupsCard(controller: controller),
                  const SizedBox(height: AtlasSpace.lg),
                  _UrgentTicketsCard(controller: controller),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final auth = Get.find<AuthController>();
    final staff = auth.currentStaff.value;
    final name = staff?.displayName.split(' ').first ??
        staff?.email.split('@').first ??
        'there';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    return '$greeting, $name';
  }
}

// ─── KPI CARD ───────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? delta;
  final bool deltaPositive;
  final bool deltaWarning;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    this.delta,
    this.deltaPositive = false,
    this.deltaWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final deltaColor = deltaWarning
        ? AtlasColors.warning
        : deltaPositive
            ? AtlasColors.success
            : AtlasColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(AtlasSpace.xl),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
        boxShadow: AtlasElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.toUpperCase(),
                  style: AtlasText.tiny.copyWith(
                      fontWeight: FontWeight.w700, letterSpacing: 0.6)),
              Container(
                padding: const EdgeInsets.all(AtlasSpace.xs + 2),
                decoration: BoxDecoration(
                  color: AtlasColors.accentSoft,
                  borderRadius: BorderRadius.circular(AtlasRadius.sm),
                ),
                child: Icon(icon, size: 14, color: AtlasColors.accent),
              ),
            ],
          ),
          const SizedBox(height: AtlasSpace.md),
          Text(
            value,
            style: AtlasText.h1.copyWith(fontSize: 28, height: 1.0),
          ),
          if (delta != null) ...[
            const SizedBox(height: AtlasSpace.sm),
            Row(
              children: [
                if (deltaPositive)
                  Icon(Icons.arrow_upward, size: 11, color: deltaColor)
                else if (deltaWarning)
                  Icon(Icons.warning_amber_rounded,
                      size: 11, color: deltaColor),
                if (deltaPositive || deltaWarning)
                  const SizedBox(width: 3),
                Text(
                  delta!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: deltaColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── RECENT SIGNUPS ─────────────────────────────────────────────────────

class _RecentSignupsCard extends StatelessWidget {
  final HomeController controller;
  const _RecentSignupsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Recent customer signups',
      action: 'View all',
      onAction: () => Get.toNamed(AtlasRoutes.customers),
      child: Obx(() {
        final signups = controller.recentSignups;
        if (signups.isEmpty) return const _EmptyState(message: 'No customers yet.');
        return Column(
          children: signups.map((o) => _OrgRow(org: o)).toList(),
        );
      }),
    );
  }
}

class _OrgRow extends StatelessWidget {
  final CustomerOrg org;
  const _OrgRow({required this.org});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d');
    return InkWell(
      onTap: () => Get.toNamed(AtlasRoutes.customers),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AtlasSpace.xl, vertical: AtlasSpace.md),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AtlasColors.cardBorderSubtle)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AtlasColors.accentSoft,
                borderRadius: BorderRadius.circular(AtlasRadius.sm),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.business_rounded,
                  size: 14, color: AtlasColors.accent),
            ),
            const SizedBox(width: AtlasSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org.name,
                    style: AtlasText.body.copyWith(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    org.industry ?? org.email ?? '—',
                    style: AtlasText.tiny,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              org.createdAt != null ? df.format(org.createdAt!) : '—',
              style: AtlasText.tiny.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── URGENT TICKETS ─────────────────────────────────────────────────────

class _UrgentTicketsCard extends StatelessWidget {
  final HomeController controller;
  const _UrgentTicketsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Open tickets',
      action: 'View queue',
      onAction: () => Get.toNamed(AtlasRoutes.tickets),
      child: Obx(() {
        final tickets = controller.urgentOpenTickets;
        if (tickets.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AtlasSpace.xl, vertical: AtlasSpace.xxxl),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AtlasColors.success, size: 28),
                  SizedBox(height: AtlasSpace.sm),
                  Text(
                    'You\'re all caught up',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AtlasColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'No open tickets right now.',
                    style: AtlasText.tiny,
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: tickets.map((t) => _TicketRow(ticket: t)).toList(),
        );
      }),
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
        padding: const EdgeInsets.symmetric(
            horizontal: AtlasSpace.xl, vertical: AtlasSpace.md),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AtlasColors.cardBorderSubtle)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ticket.ticketNumber,
                        style: AtlasText.tiny.copyWith(
                            fontWeight: FontWeight.w700, letterSpacing: 0.4),
                      ),
                      const SizedBox(width: AtlasSpace.sm),
                      PriorityPill(priority: ticket.priority),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ticket.subject,
                    style: AtlasText.body.copyWith(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(ticket.orgName,
                      style: AtlasText.tiny, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: AtlasSpace.sm),
            const Icon(Icons.chevron_right,
                size: 16, color: AtlasColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─── SHARED ─────────────────────────────────────────────────────────────

class _DashboardCard extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.child,
    this.action,
    this.onAction,
  });

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
                AtlasSpace.md, AtlasSpace.md),
            child: Row(
              children: [
                Expanded(child: Text(title, style: AtlasText.h3)),
                if (action != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AtlasSpace.sm, vertical: AtlasSpace.xs),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(action!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AtlasColors.accent,
                        )),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AtlasSpace.xl, vertical: AtlasSpace.xxl),
      child: Center(child: Text(message, style: AtlasText.smallMuted)),
    );
  }
}
