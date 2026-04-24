/// Atlas environment configuration.
///
/// Inject via `--dart-define`:
/// ```
/// flutter run -d chrome --dart-define=ENV=prod
/// ```
class AppConfig {
  AppConfig._();

  static const String env = String.fromEnvironment('ENV', defaultValue: 'dev');

  static bool get isProduction => env == 'prod';
  static bool get isStaging => env == 'staging';
  static bool get isDev => env == 'dev';

  /// Customer-facing PagentZ web app URL — used to open impersonation sessions.
  static const String pagentzWebUrl = String.fromEnvironment(
    'PAGENTZ_WEB_URL',
    defaultValue: 'https://pagentz.web.app',
  );

  /// Bootstrap admin — auto-provisioned on first sign-in attempt.
  /// After the first admin exists, they can create more staff from the
  /// Staff Management screen.
  static const String bootstrapAdminEmail = 'admin@pagentz.com';
  static const String bootstrapAdminPassword = 'atlas@2026';
  static const String bootstrapAdminName = 'Atlas Admin';

  /// Max impersonation session length (1 hour).
  static const Duration maxImpersonationDuration = Duration(hours: 1);

  /// Idle timeout — auto-lock UI after this long of no activity.
  static const Duration idleTimeout = Duration(minutes: 30);

  /// Hard session timeout — re-auth after this long.
  static const Duration sessionTimeout = Duration(hours: 8);

  /// Force password rotation after this long.
  static const Duration passwordRotationMaxAge = Duration(days: 90);

  static String get envLabel {
    switch (env) {
      case 'prod':
        return 'PROD';
      case 'staging':
        return 'STAGING';
      default:
        return 'DEV';
    }
  }

  static bool get showEnvBanner => !isProduction;
}
