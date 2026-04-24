import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/atlas_colors.dart';
import '../../../utils/routes.dart';
import '../controller/auth_controller.dart';

/// Boots the app: tries to restore the staff session, then routes to home or login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = Get.find<AuthController>();
    final staff = await auth.tryRestoreSession();
    if (!mounted) return;
    if (staff == null) {
      Get.offAllNamed(AtlasRoutes.login);
      return;
    }
    if (staff.passwordExpired()) {
      Get.offAllNamed(AtlasRoutes.passwordRotation);
      return;
    }
    Get.offAllNamed(AtlasRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AtlasColors.sidebarBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AtlasColors.accent),
            SizedBox(height: 18),
            Text(
              'Loading Atlas…',
              style: TextStyle(color: AtlasColors.sidebarTextMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
