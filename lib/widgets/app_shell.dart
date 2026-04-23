import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/models/staff_user_model.dart';
import '../modules/auth/controller/auth_controller.dart';
import '../theme/atlas_colors.dart';
import '../theme/atlas_text.dart';
import '../utils/routes.dart';

/// Refined Atlas v3 app layout — premium dark sidebar + light content area.
class AppShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final String pageTitle;
  final String? pageSubtitle;
  final List<Widget>? actions;

  const AppShell({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.pageTitle,
    this.pageSubtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AtlasColors.pageBg,
      drawer:
          isWide ? null : Drawer(child: _Sidebar(currentRoute: currentRoute)),
      body: Row(
        children: [
          if (isWide) _Sidebar(currentRoute: currentRoute),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  pageTitle: pageTitle,
                  pageSubtitle: pageSubtitle,
                  isWide: isWide,
                  actions: actions,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AtlasSpace.xxl,
                      AtlasSpace.xl,
                      AtlasSpace.xxl,
                      AtlasSpace.xxxl,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: child,
                    ),
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

// ─── SIDEBAR ────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final String currentRoute;
  const _Sidebar({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: AtlasColors.sidebarBg,
        border: Border(
            right: BorderSide(color: AtlasColors.sidebarBorderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SidebarBrand(),
          const SizedBox(height: AtlasSpace.lg),

          // Main navigation
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AtlasSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SidebarSection('Workspace'),
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: 'Home',
                    route: AtlasRoutes.home,
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.business_outlined,
                    activeIcon: Icons.business_rounded,
                    label: 'Customers',
                    route: AtlasRoutes.customers,
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.inbox_outlined,
                    activeIcon: Icons.inbox_rounded,
                    label: 'Tickets',
                    route: AtlasRoutes.tickets,
                    currentRoute: currentRoute,
                  ),
                  const SizedBox(height: AtlasSpace.lg),
                  Obx(() {
                    final me =
                        Get.find<AuthController>().currentStaff.value;
                    final canSee = me != null &&
                        me.role.isAtLeast(StaffRole.admin);
                    if (!canSee) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SidebarSection('Administration'),
                        _NavItem(
                          icon: Icons.people_outline,
                          activeIcon: Icons.people_rounded,
                          label: 'Staff',
                          route: AtlasRoutes.staff,
                          currentRoute: currentRoute,
                        ),
                        _NavItem(
                          icon: Icons.history_outlined,
                          activeIcon: Icons.history_rounded,
                          label: 'Audit Log',
                          route: AtlasRoutes.audit,
                          currentRoute: currentRoute,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          const _SidebarUserCard(),
        ],
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AtlasSpace.xl, AtlasSpace.xl, AtlasSpace.xl, AtlasSpace.xs),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AtlasColors.accent, AtlasColors.accentActive],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AtlasRadius.md),
              boxShadow: [
                BoxShadow(
                  color: AtlasColors.accent.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.shield_outlined,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: AtlasSpace.sm + 2),
          const Text('Atlas', style: AtlasText.sidebarBrand),
          const SizedBox(width: AtlasSpace.xs),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AtlasSpace.xs + 1, vertical: 1),
            decoration: BoxDecoration(
              color: AtlasColors.sidebarHover,
              borderRadius: BorderRadius.circular(AtlasRadius.xs),
            ),
            child: const Text(
              'BETA',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AtlasColors.sidebarTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String label;
  const _SidebarSection(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AtlasSpace.sm, AtlasSpace.md, AtlasSpace.sm, AtlasSpace.xs),
      child: Text(label.toUpperCase(), style: AtlasText.sidebarSection),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final String currentRoute;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.currentRoute,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.currentRoute == widget.route ||
        (widget.route == AtlasRoutes.customers &&
            widget.currentRoute == AtlasRoutes.customerDetail) ||
        (widget.route == AtlasRoutes.tickets &&
            widget.currentRoute == AtlasRoutes.ticketDetail);

    final bg = isActive
        ? AtlasColors.sidebarHover
        : _hover
            ? AtlasColors.sidebarHover.withValues(alpha: 0.5)
            : Colors.transparent;
    final fg = isActive ? AtlasColors.sidebarText : AtlasColors.sidebarTextMuted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isActive ? null : () => Get.offAllNamed(widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(
              horizontal: AtlasSpace.sm + 2, vertical: AtlasSpace.sm),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AtlasRadius.sm),
          ),
          child: Row(
            children: [
              Icon(isActive ? widget.activeIcon : widget.icon,
                  size: 17, color: fg),
              const SizedBox(width: AtlasSpace.md - 2),
              Expanded(
                child: Text(widget.label,
                    style:
                        isActive ? AtlasText.sidebarItemActive : AtlasText.sidebarItem),
              ),
              if (isActive)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AtlasColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarUserCard extends StatelessWidget {
  const _SidebarUserCard();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final staff = auth.currentStaff.value;
      if (staff == null) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.all(AtlasSpace.md),
        padding: const EdgeInsets.all(AtlasSpace.sm + 2),
        decoration: BoxDecoration(
          color: AtlasColors.sidebarBgElevated,
          borderRadius: BorderRadius.circular(AtlasRadius.lg),
          border: Border.all(color: AtlasColors.sidebarBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AtlasColors.accent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(staff.displayName, staff.email),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: AtlasSpace.sm + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    staff.displayName.isNotEmpty
                        ? staff.displayName
                        : staff.email.split('@').first,
                    style: const TextStyle(
                      color: AtlasColors.sidebarText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    staff.role.label,
                    style: const TextStyle(
                      color: AtlasColors.sidebarTextSubtle,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            _SidebarIconButton(
              icon: Icons.logout,
              tooltip: 'Sign out',
              onTap: () async {
                await auth.signOut();
                Get.offAllNamed(AtlasRoutes.login);
              },
            ),
          ],
        ),
      );
    });
  }

  String _initials(String displayName, String email) {
    if (displayName.isNotEmpty) {
      final parts = displayName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return parts.first.substring(0, 1).toUpperCase();
    }
    return email.substring(0, 1).toUpperCase();
  }
}

class _SidebarIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _SidebarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_SidebarIconButton> createState() => _SidebarIconButtonState();
}

class _SidebarIconButtonState extends State<_SidebarIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(AtlasSpace.xs + 2),
            decoration: BoxDecoration(
              color: _hover ? AtlasColors.sidebarHover : Colors.transparent,
              borderRadius: BorderRadius.circular(AtlasRadius.xs + 1),
            ),
            child: Icon(widget.icon, size: 15, color: AtlasColors.sidebarTextMuted),
          ),
        ),
      ),
    );
  }
}

// ─── TOP BAR ────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String pageTitle;
  final String? pageSubtitle;
  final bool isWide;
  final List<Widget>? actions;

  const _TopBar({
    required this.pageTitle,
    required this.pageSubtitle,
    required this.isWide,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border(
          bottom: BorderSide(color: AtlasColors.divider),
        ),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AtlasSpace.xxl, vertical: AtlasSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isWide)
            Padding(
              padding: const EdgeInsets.only(right: AtlasSpace.sm),
              child: IconButton(
                icon: const Icon(Icons.menu, size: 20),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pageTitle, style: AtlasText.h2),
                if (pageSubtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(pageSubtitle!, style: AtlasText.smallMuted),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
