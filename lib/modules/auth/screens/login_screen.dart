import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/atlas_colors.dart';
import '../../../utils/routes.dart';
import '../controller/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left brand panel — only visible on wider screens
          if (MediaQuery.of(context).size.width > 900)
            Expanded(flex: 5, child: _BrandPanel()),

          // Right login form
          Expanded(
            flex: 4,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: _LoginForm(formKey: _formKey, controller: controller),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AtlasColors.sidebarBg, Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AtlasColors.accent, AtlasColors.accentHover],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Text(
              'PA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'PagentZ Atlas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Internal admin console for the staff team.\nA map of every customer. A record of every action.',
            style: TextStyle(
              color: AtlasColors.sidebarTextMuted,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          _BrandFeature(icon: Icons.search_rounded, label: 'Search & view every customer organization'),
          _BrandFeature(icon: Icons.shield_outlined, label: 'Safe, audited customer impersonation'),
          _BrandFeature(icon: Icons.support_agent_outlined, label: 'Unified support ticket queue'),
          _BrandFeature(icon: Icons.lock_outline, label: 'MFA-required, role-based access'),
        ],
      ),
    );
  }
}

class _BrandFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BrandFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AtlasColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AtlasColors.accent, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AtlasColors.sidebarText, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final AuthController controller;

  const _LoginForm({required this.formKey, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Sign in to Atlas',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AtlasColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use the credentials provided by your Atlas admin.',
            style: TextStyle(color: AtlasColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),

          // Error banner
          Obx(() {
            if (controller.errorMessage.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AtlasColors.dangerSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AtlasColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AtlasColors.danger, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.errorMessage.value,
                      style: const TextStyle(
                        color: AtlasColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    color: AtlasColors.danger,
                    onPressed: controller.clearError,
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 4),
          Row(
            children: const [
              Expanded(child: Divider(color: AtlasColors.cardBorder)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Sign in with email',
                  style: TextStyle(color: AtlasColors.textMuted, fontSize: 12),
                ),
              ),
              Expanded(child: Divider(color: AtlasColors.cardBorder)),
            ],
          ),
          const SizedBox(height: 22),

          TextFormField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@pagentz.com',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email required';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controller.passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Password required' : null,
          ),
          const SizedBox(height: 22),
          Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final ok = await controller.signInWithEmail();
                        if (ok) Get.offAllNamed(AtlasRoutes.home);
                      },
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Sign in'),
              )),
          const SizedBox(height: 28),
          const Center(
            child: Text(
              'Atlas is restricted to authorised staff only. Accounts are created by an admin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AtlasColors.textMuted, fontSize: 11.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
