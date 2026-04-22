import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/config/atlas_config.dart';
import 'core/config/firebase_options.dart';
import 'core/services/staff_auth_service.dart';
import 'modules/auth/controller/staff_auth_controller.dart';
import 'modules/audit/screens/audit_log_screen.dart';
import 'modules/auth/screens/access_denied_screen.dart';
import 'modules/auth/screens/login_screen.dart';
import 'modules/auth/screens/mfa_challenge_screen.dart';
import 'modules/auth/screens/mfa_enrollment_screen.dart';
import 'modules/customers/screens/customer_detail_screen.dart';
import 'modules/customers/screens/customer_directory_screen.dart';
import 'modules/home/screens/home_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  StaffAuthService.instance.configureTenant();
  runApp(const AtlasApp());
}

class AtlasApp extends StatelessWidget {
  const AtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(StaffAuthController(), permanent: true);

    return GetMaterialApp(
      title: AtlasConfig.productName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AtlasConfig.primarySeed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const _AuthGate()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/mfa-enroll', page: () => const MfaEnrollmentScreen()),
        GetPage(name: '/mfa-challenge', page: () => const MfaChallengeScreen()),
        GetPage(name: '/access-denied', page: () => const AccessDeniedScreen()),
        GetPage(name: '/home', page: () => const HomeDashboard()),
        GetPage(
            name: '/customers',
            page: () => const CustomerDirectoryScreen()),
        GetPage(
            name: '/customers/:orgId',
            page: () => const CustomerDetailScreen()),
        GetPage(name: '/audit', page: () => const AuditLogScreen()),
      ],
    );
  }
}

/// Shown at '/' while the auth state resolves on app boot. Routing itself is
/// handled by `StaffAuthController._handleGateChange`.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
