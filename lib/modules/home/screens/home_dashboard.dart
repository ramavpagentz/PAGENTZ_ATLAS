import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/atlas_config.dart';
import '../../../core/models/staff_user_model.dart';
import '../../auth/controller/staff_auth_controller.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<StaffAuthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(AtlasConfig.productName),
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    c.staffUser.value?.email ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70),
                  ),
                ),
              )),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => c.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Obx(() {
          final u = c.staffUser.value;
          if (u == null) return const CircularProgressIndicator();
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Welcome, ${u.displayName.isEmpty ? u.email : u.displayName}',
                            style:
                                Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text('Role: ${u.staffRole?.value ?? "unknown"}',
                              style:
                                  const TextStyle(color: Colors.white60)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                        icon: Icons.history_outlined,
                        title: 'Activity',
                        subtitle: 'Phase 3',
                        enabled: false,
                      ),
                      _NavCard(
                        icon: Icons.support_agent_outlined,
                        title: 'Support',
                        subtitle: 'Phase 5',
                        enabled: false,
                      ),
                      _NavCard(
                        icon: Icons.shield_outlined,
                        title: 'Audit log',
                        subtitle: u.staffRole == StaffRole.admin ||
                                u.staffRole == StaffRole.owner
                            ? 'Staff actions'
                            : 'Admin/owner only',
                        enabled: u.staffRole == StaffRole.admin ||
                            u.staffRole == StaffRole.owner,
                        onTap: () => Get.toNamed('/audit'),
                      ),
                      _NavCard(
                        icon: Icons.group_outlined,
                        title: 'Staff',
                        subtitle: u.staffRole == StaffRole.admin ||
                                u.staffRole == StaffRole.owner
                            ? 'Add / role / disable'
                            : 'Admin/owner only',
                        enabled: u.staffRole == StaffRole.admin ||
                            u.staffRole == StaffRole.owner,
                        onTap: () => Get.toNamed('/staff'),
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
          );
        }),
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
