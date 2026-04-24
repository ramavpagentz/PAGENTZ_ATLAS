import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/config/app_config.dart';
import 'core/services/session_service.dart';
import 'modules/auth/controller/auth_controller.dart';
import 'modules/auth/screens/login_screen.dart';
import 'modules/auth/screens/mfa_enrollment_screen.dart';
import 'modules/auth/screens/password_rotation_screen.dart';
import 'modules/auth/screens/splash_screen.dart';
import 'modules/audit/screens/audit_log_screen.dart';
import 'modules/customers/screens/customer_detail_screen.dart';
import 'modules/customers/screens/customer_directory_screen.dart';
import 'modules/home/screens/home_screen.dart';
import 'modules/staff/screens/staff_management_screen.dart';
import 'modules/tickets/screens/ticket_detail_screen.dart';
import 'modules/tickets/screens/ticket_queue_screen.dart';
import 'theme/atlas_colors.dart';
import 'theme/atlas_theme.dart';
import 'utils/routes.dart';
import 'widgets/error_pages.dart';

class AtlasApp extends StatelessWidget {
  const AtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PagentZ Atlas',
      debugShowCheckedModeBanner: false,
      theme: AtlasTheme.light(),
      // Register the AuthController once for the lifetime of the app so
      // its TextEditingControllers are never accidentally disposed.
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
      }),
      initialRoute: AtlasRoutes.splash,
      unknownRoute: GetPage(name: '/404', page: () => const NotFoundPage()),
      builder: (context, child) {
        Widget content = child ?? const SizedBox.shrink();
        // Track every user input for idle timeout
        content = SessionActivityWrapper(child: content);
        if (AppConfig.showEnvBanner) {
          content = Banner(
            message: AppConfig.envLabel,
            location: BannerLocation.topStart,
            color: AppConfig.isStaging
                ? const Color(0xFFFFA94D)
                : AtlasColors.accent,
            child: content,
          );
        }
        return content;
      },
      getPages: [
        GetPage(name: AtlasRoutes.splash, page: () => const SplashScreen()),
        GetPage(name: AtlasRoutes.login, page: () => LoginScreen()),
        GetPage(
            name: AtlasRoutes.passwordRotation,
            page: () => const PasswordRotationScreen()),
        GetPage(
            name: AtlasRoutes.mfaEnrollment,
            page: () => const MfaEnrollmentScreen()),
        GetPage(name: AtlasRoutes.home, page: () => HomeScreen()),
        GetPage(
          name: AtlasRoutes.customers,
          page: () => CustomerDirectoryScreen(),
        ),
        GetPage(
          name: AtlasRoutes.customerDetail,
          page: () => const CustomerDetailScreen(),
        ),
        GetPage(name: AtlasRoutes.tickets, page: () => TicketQueueScreen()),
        GetPage(name: AtlasRoutes.ticketDetail, page: () => const TicketDetailScreen()),
        GetPage(name: AtlasRoutes.staff, page: () => StaffManagementScreen()),
        GetPage(name: AtlasRoutes.audit, page: () => AuditLogScreen()),
      ],
    );
  }
}
