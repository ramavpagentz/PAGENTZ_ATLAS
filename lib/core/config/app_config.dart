/// Atlas environment configuration.
///
/// `ENV` is the only required `--dart-define`. Everything else has an
/// env-aware default that picks the right value automatically based on `ENV`.
/// You can still override any value with a `--dart-define` of the same name.
///
/// Supported envs: `staging`, `prod`. `dev` is also accepted but Atlas
/// targets only staging + production per the agreed rollout (Option C).
///
/// ```sh
/// # Staging Atlas → talks to pagentz-staging Firebase
/// flutter run -d chrome --dart-define=ENV=staging
///
/// # Production Atlas → talks to pagentz-production Firebase
/// flutter run -d chrome --dart-define=ENV=prod
/// ```
class AppConfig {
  AppConfig._();

  static const String env = String.fromEnvironment('ENV', defaultValue: 'staging');

  static bool get isProduction => env == 'prod';
  static bool get isStaging => env == 'staging';
  static bool get isDev => env == 'dev';

  /// Customer-facing PagentZ web app URL — used to open impersonation sessions.
  /// Each Atlas env hands off to the matching customer-app env.
  static String get pagentzWebUrl {
    const override = String.fromEnvironment('PAGENTZ_WEB_URL');
    if (override.isNotEmpty) return override;
    switch (env) {
      case 'prod':
        return 'https://pagentz-production.web.app';
      case 'staging':
        return 'https://pagentz-staging.web.app';
      default:
        return 'https://pagentz.web.app';
    }
  }

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
