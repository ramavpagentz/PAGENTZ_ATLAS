import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/models/staff_user_model.dart';
import '../modules/auth/controller/auth_controller.dart';
import '../theme/atlas_colors.dart';
import '../utils/routes.dart';

/// Main authenticated app layout: dark sidebar + top bar + content area.
class AppShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final String pageTitle;

  const AppShell({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.pageTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AtlasColors.pageBg,
      drawer: isWide ? null : Drawer(child: _Sidebar(currentRoute: currentRoute)),
      body: Row(
        children: [
          if (isWide) _Sidebar(currentRoute: currentRoute),
          Expanded(
            child: Column(
              children: [
                _TopBar(pageTitle: pageTitle, isWide: isWide),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: child,
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

class _Sidebar extends StatelessWidget {
  final String currentRoute;
  const _Sidebar({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AtlasColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AtlasColors.accent, AtlasColors.accentHover],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'PA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Atlas',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          // Nav items
          _NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Home',
            route: AtlasRoutes.home,
            currentRoute: currentRoute,
          ),
          _NavItem(
            icon: Icons.business_outlined,
            label: 'Customers',
            route: AtlasRoutes.customers,
            currentRoute: currentRoute,
          ),
          _NavItem(
            icon: Icons.support_agent_outlined,
            label: 'Tickets',
            route: AtlasRoutes.tickets,
            currentRoute: currentRoute,
          ),
          // Staff management: admin/owner only
          Obx(() {
            final staff = Get.find<AuthController>().currentStaff.value;
            final canSee = staff != null && staff.role.isAtLeast(StaffRole.admin);
            return _NavItem(
              icon: Icons.people_outline,
              label: 'Staff',
              route: AtlasRoutes.staff,
              currentRoute: currentRoute,
              disabled: !canSee,
            );
          }),
          // Audit log: only admin/owner staff can access it
          Obx(() {
            final staff = Get.find<AuthController>().currentStaff.value;
            final canSee = staff != null && staff.role.isAtLeast(StaffRole.admin);
            return _NavItem(
              icon: Icons.receipt_long_outlined,
              label: 'Audit Log',
              route: AtlasRoutes.audit,
              currentRoute: currentRoute,
              disabled: !canSee,
            );
          }),

          const Spacer(),

          // User card + logout
          _UserCard(),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final bool disabled;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentRoute == route ||
        (route == AtlasRoutes.customers &&
            currentRoute == AtlasRoutes.customerDetail);

    return InkWell(
      onTap: disabled || isActive ? null : () => Get.offAllNamed(route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AtlasColors.accent.withValues(alpha: 0.18) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: disabled
                  ? AtlasColors.sidebarTextMuted.withValues(alpha: 0.5)
                  : isActive
                      ? AtlasColors.accent
                      : AtlasColors.sidebarTextMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: disabled
                      ? AtlasColors.sidebarTextMuted.withValues(alpha: 0.5)
                      : isActive
                          ? Colors.white
                          : AtlasColors.sidebarText,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (disabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AtlasColors.sidebarTextMuted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'soon',
                  style: TextStyle(
                    color: AtlasColors.sidebarTextMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final staff = auth.currentStaff.value;
      if (staff == null) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AtlasColors.sidebarBgHover,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AtlasColors.accent,
                  child: Text(
                    (staff.displayName.isNotEmpty
                            ? staff.displayName[0]
                            : staff.email[0])
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.displayName.isNotEmpty
                            ? staff.displayName
                            : staff.email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        staff.role.label,
                        style: const TextStyle(
                          color: AtlasColors.sidebarTextMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  await auth.signOut();
                  Get.offAllNamed(AtlasRoutes.login);
                },
                icon: const Icon(Icons.logout, size: 14, color: AtlasColors.sidebarTextMuted),
                label: const Text(
                  'Sign out',
                  style: TextStyle(
                    color: AtlasColors.sidebarTextMuted,
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  final String pageTitle;
  final bool isWide;
  const _TopBar({required this.pageTitle, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border(bottom: BorderSide(color: AtlasColors.cardBorder)),
      ),
      child: Row(
        children: [
          if (!isWide)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          Text(
            pageTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AtlasColors.textPrimary,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
