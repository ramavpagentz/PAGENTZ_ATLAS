import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/config/atlas_config.dart';
import '../../../core/models/staff_user_model.dart';
import '../../auth/controller/staff_auth_controller.dart';
import '../controller/home_kpi_controller.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<StaffAuthController>();
    final kpi = Get.put(HomeKpiController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(AtlasConfig.productName),
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    auth.staffUser.value?.email ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70),
                  ),
                ),
              )),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Obx(() {
          final u = auth.staffUser.value;
          if (u == null) return const CircularProgressIndicator();
          final canManage = u.staffRole == StaffRole.admin ||
              u.staffRole == StaffRole.owner;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WelcomeCard(displayName: u.displayName, email: u.email, role: u.staffRole),
                    const SizedBox(height: 20),
                    _KpiRow(kpi: kpi),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _NavCard(
                          icon: Icons.business_outlined,
                          title: 'Customers',
                          subtitle: 'Directory + detail',
                          enabled: true,
                          onTap: () => Get.toNamed('/customers'),
                        ),
                        _NavCard(
                          icon: Icons.support_agent_outlined,
                          title: 'Support',
                          subtitle: 'Ticket queue',
                          enabled: true,
                          onTap: () => Get.toNamed('/tickets'),
                        ),
                        _NavCard(
                          icon: Icons.shield_outlined,
                          title: 'Audit log',
                          subtitle: canManage
                              ? 'Staff actions'
                              : 'Admin/owner only',
                          enabled: canManage,
                          onTap: () => Get.toNamed('/audit'),
                        ),
                        _NavCard(
                          icon: Icons.group_outlined,
                          title: 'Staff',
                          subtitle: canManage
                              ? 'Add / role / disable'
                              : 'Admin/owner only',
                          enabled: canManage,
                          onTap: () => Get.toNamed('/staff'),
                        ),
                        _NavCard(
                          icon: Icons.history_outlined,
                          title: 'Activity',
                          subtitle: 'On customer detail',
                          enabled: false,
                        ),
                        _NavCard(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          subtitle: 'Phase 8',
                          enabled: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String displayName;
  final String email;
  final StaffRole? role;
  const _WelcomeCard({
    required this.displayName,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AtlasConfig.primarySeed,
              child: Text(
                (displayName.isEmpty ? email : displayName)[0].toUpperCase(),
                style:
                    const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${displayName.isEmpty ? email : displayName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text('Role: ${role?.value ?? "unknown"}',
                      style: const TextStyle(color: Colors.white60)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final HomeKpiController kpi;
  const _KpiRow({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final k = kpi.kpis.value;
      final loading = kpi.loading.value;
      if (loading && k == null) {
        return const SizedBox(
          height: 110,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (k == null) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            kpi.error.value ?? 'No KPIs yet',
            style: const TextStyle(color: Colors.white60),
          ),
        );
      }
      return GridView.count(
        shrinkWrap: true,
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.0,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _KpiCard(
            label: 'Customers',
            value: _fmt(k.totalCustomers),
            sub: '+${k.customersLast7d} last 7d / +${k.customersLast30d} last 30d',
            icon: Icons.business_outlined,
          ),
          _KpiCard(
            label: 'Active staff',
            value: _fmt(k.activeStaff),
            sub: 'Non-disabled w/ isStaff',
            icon: Icons.group_outlined,
          ),
          _KpiCard(
            label: 'Open tickets',
            value: _fmt(k.openTickets),
            sub: k.openTickets == 0 ? 'Inbox zero' : 'Status new or open',
            icon: Icons.support_agent_outlined,
          ),
          _KpiCard(
            label: 'Audit events today',
            value: _fmt(k.auditEventsToday),
            sub: 'Since 00:00 UTC',
            icon: Icons.shield_outlined,
          ),
        ],
      );
    });
  }

  String _fmt(int n) => NumberFormat.decimalPattern().format(n);
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? null : Colors.white38;
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: fg),
              const SizedBox(height: 10),
              Text(title,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: fg)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11,
                      color: enabled ? Colors.white60 : Colors.white30)),
            ],
          ),
        ),
      ),
    );
  }
}
