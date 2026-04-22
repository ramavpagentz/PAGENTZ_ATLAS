import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/atlas_colors.dart';
import '../utils/routes.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ErrorScaffold(
      icon: Icons.help_outline,
      iconColor: AtlasColors.info,
      code: '404',
      title: 'Page not found',
      message:
          'The page you tried to open doesn\'t exist in Atlas. Use the sidebar to navigate.',
    );
  }
}

class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ErrorScaffold(
      icon: Icons.lock_outline,
      iconColor: AtlasColors.danger,
      code: '403',
      title: 'Access denied',
      message:
          'Your role doesn\'t have permission to view this page. Contact an admin if you think this is wrong.',
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String code;
  final String title;
  final String message;

  const _ErrorScaffold({
    required this.icon,
    required this.iconColor,
    required this.code,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.pageBg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 38),
                ),
                const SizedBox(height: 22),
                Text(
                  code,
                  style: const TextStyle(
                    color: AtlasColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AtlasColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AtlasColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () => Get.offAllNamed(AtlasRoutes.home),
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
