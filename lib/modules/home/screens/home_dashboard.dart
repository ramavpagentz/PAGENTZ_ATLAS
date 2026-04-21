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
          return Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Welcome, ${u.displayName.isEmpty ? u.email : u.displayName}'),
                  const SizedBox(height: 8),
                  Text('Role: ${u.staffRole?.value ?? "unknown"}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  const Text('Phase 2 coming: Customer Directory',
                      style: TextStyle(color: Colors.white60)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
