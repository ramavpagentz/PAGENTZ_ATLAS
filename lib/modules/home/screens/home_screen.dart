import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/customer_org_model.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../theme/atlas_colors.dart';
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
      pageTitle: 'Home',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Welcome(),
          const SizedBox(height: 24),

          // KPIs
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 1100
                  ? 4
                  : c.maxWidth > 700
                      ? 2
                      : 1;
              return Obx(() {
                // Touch the observables Obx should watch.
                final total = controller.totalCustomers;
                final newThisWeek = controller.newThisWeek;
                final active = controller.activeThisMonth;
                final open = controller.openTicketCount;
                final urgent = controller.urgentTicketCount;
                final healthy = controller.systemHealthy;

                return GridView.count(
                  crossAxisCount: cols,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  shrinkWrap: true,
                  childAspectRatio: 2.6,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _Kpi(
                      label: 'Total Customers',
                      value: '$total',
                      sublabel: '+$newThisWeek this week',
                      icon: Icons.business,
                      color: AtlasColors.accent,
                    ),
                    _Kpi(
                      label: 'Active This Month',
                      value: '$active',
                      sublabel: 'logged in last 30d',
                      icon: Icons.trending_up,
                      color: AtlasColors.info,
                    ),
                    _Kpi(
                      label: 'Open Tickets',
                      value: '$open',
                      sublabel: '$urgent urgent',
                      icon: Icons.support_agent,
                      color: urgent > 0 ? AtlasColors.warning : AtlasColors.accent,
                    ),
                    _Kpi(
                      label: 'System Health',
                      value: healthy ? 'OK' : '…',
                      sublabel: 'Firestore reachable',
                      icon: healthy ? Icons.check_circle : Icons.sync,
                      color: healthy ? AtlasColors.success : AtlasColors.warning,
                    ),
                  ],
                );
              });
            },
          ),

          const SizedBox(height: 24),

          // Two-column: recent signups + urgent tickets
          LayoutBuilder(builder: (context, c) {
            final isWide = c.maxWidth > 900;
            final signups = _RecentSignupsCard(controller: controller);
            final urgent = _UrgentTicketsCard(controller: controller);

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: signups),
                  const SizedBox(width: 14),
                  Expanded(child: urgent),
                ],
              );
            }
            return Column(children: [signups, const SizedBox(height: 14), urgent]);
          }),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AtlasColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Atlas at a glance',
            style: TextStyle(color: AtlasColors.textSecondary, fontSize: 13),
          ),
        ],
      );
    });
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final IconData icon;
  final Color color;
  const _Kpi({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AtlasColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AtlasColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                Text(
                  sublabel,
                  style: const TextStyle(
                    color: AtlasColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSignupsCard extends StatelessWidget {
  final HomeController controller;
  const _RecentSignupsCard({required this.controller});

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
          _CardHeader(
            title: 'Recent customer signups',
            actionLabel: 'View all',
            onAction: () => Get.toNamed(AtlasRoutes.customers),
          ),
          Obx(() {
            final signups = controller.recentSignups;
            if (signups.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: Text(
                    'No customers yet.',
                    style: TextStyle(color: AtlasColors.textMuted, fontSize: 13),
                  ),
                ),
              );
            }
            return Column(
              children: signups.map((o) => _OrgRow(org: o)).toList(),
            );
          }),
        ],
      ),
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
      onTap: () {
        // Open the customer detail view.
        Get.toNamed(AtlasRoutes.customers);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AtlasColors.cardBorder)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AtlasColors.accentSoft,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.business, size: 14, color: AtlasColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    org.industry ?? org.email ?? '—',
                    style: const TextStyle(
                      color: AtlasColors.textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              org.createdAt != null ? df.format(org.createdAt!) : '—',
              style: const TextStyle(
                color: AtlasColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgentTicketsCard extends StatelessWidget {
  final HomeController controller;
  const _UrgentTicketsCard({required this.controller});

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
          _CardHeader(
            title: 'Open tickets needing attention',
            actionLabel: 'View queue',
            onAction: () => Get.toNamed(AtlasRoutes.tickets),
          ),
          Obx(() {
            final tickets = controller.urgentOpenTickets;
            if (tickets.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: AtlasColors.success, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'No open tickets — you\'re caught up.',
                        style: TextStyle(color: AtlasColors.textSecondary, fontSize: 13),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ticket.ticketNumber,
                        style: const TextStyle(
                          color: AtlasColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      PriorityPill(priority: ticket.priority),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.subject,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ticket.orgName,
                    style: const TextStyle(
                      color: AtlasColors.textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
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

class _CardHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  const _CardHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AtlasColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: AtlasColors.accent),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
