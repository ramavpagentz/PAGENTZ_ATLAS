import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../utils/routes.dart';
import '../controller/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 960;

    return Scaffold(
      backgroundColor: AtlasColors.pageBg,
      body: Row(
        children: [
          if (isWide)
            Expanded(flex: 5, child: const _BrandPanel()),
          Expanded(
            flex: 4,
            child: Container(
              color: AtlasColors.cardBg,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AtlasSpace.huge),
                    child: _LoginForm(formKey: _formKey, controller: controller),
                  ),
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
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AtlasColors.sidebarBg, Color(0xFF1A1A1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Subtle grid pattern background
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(AtlasSpace.huge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AtlasColors.accent, AtlasColors.accentActive],
                        ),
                        borderRadius: BorderRadius.circular(AtlasRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: AtlasColors.accent.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.shield_outlined,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: AtlasSpace.md),
                    const Text(
                      'Atlas',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'The control center\nfor every customer.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: AtlasSpace.xl),
                Text(
                  'Atlas is the internal admin console for the PagentZ\nstaff team — search every customer, audit every action,\nresolve every issue from one place.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 15,
                    height: 1.6,
                    letterSpacing: 0.0,
                  ),
                ),
                const Spacer(),
                Row(
                  children: const [
                    _Feature(icon: Icons.search, label: 'Unified directory'),
                    SizedBox(width: AtlasSpace.xxxl),
                    _Feature(icon: Icons.shield_outlined, label: 'Safe impersonation'),
                    SizedBox(width: AtlasSpace.xxxl),
                    _Feature(icon: Icons.history, label: 'Full audit trail'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const step = 40.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Feature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: AtlasSpace.sm),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
          const Text('Sign in to Atlas', style: AtlasText.h1),
          const SizedBox(height: AtlasSpace.xs),
          const Text(
            'Use the credentials provided by your Atlas admin.',
            style: AtlasText.smallMuted,
          ),
          const SizedBox(height: AtlasSpace.xxl),

          // Error banner
          Obx(() {
            if (controller.errorMessage.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: AtlasSpace.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AtlasSpace.md, vertical: AtlasSpace.sm + 2),
                decoration: BoxDecoration(
                  color: AtlasColors.dangerSoft,
                  borderRadius: BorderRadius.circular(AtlasRadius.md),
                  border: Border.all(
                      color: AtlasColors.danger.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AtlasColors.danger, size: 16),
                    const SizedBox(width: AtlasSpace.sm),
                    Expanded(
                      child: Text(
                        controller.errorMessage.value,
                        style: AtlasText.small.copyWith(
                          color: AtlasColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: controller.clearError,
                      borderRadius: BorderRadius.circular(AtlasRadius.xs),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.close,
                            color: AtlasColors.danger, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const _Label('Email'),
          const SizedBox(height: AtlasSpace.xs + 2),
          TextFormField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'you@pagentz.com'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email required';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: AtlasSpace.lg),

          const _Label('Password'),
          const SizedBox(height: AtlasSpace.xs + 2),
          TextFormField(
            controller: controller.passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Enter your password'),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Password required' : null,
          ),
          const SizedBox(height: AtlasSpace.xxl),

          Obx(() => SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          final ok = await controller.signInWithEmail();
                          if (!ok) return;
                          // Password rotation check (Atlas requires rotation
                          // every 90 days; see AppConfig.passwordRotationMaxAge)
                          final staff = controller.currentStaff.value;
                          if (staff != null && staff.passwordExpired()) {
                            Get.offAllNamed(AtlasRoutes.passwordRotation);
                          } else {
                            Get.offAllNamed(AtlasRoutes.home);
                          }
                        },
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue'),
                ),
              )),
          const SizedBox(height: AtlasSpace.xxl),
          Center(
            child: Text(
              'Atlas is restricted to authorised staff only.\nNeed access? Ask an admin to create your account.',
              textAlign: TextAlign.center,
              style: AtlasText.tiny.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AtlasColors.textPrimary,
      ),
    );
  }
}
