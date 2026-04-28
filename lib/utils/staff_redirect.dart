import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import '../core/services/audit_log_service.dart';

/// Builds + opens links into the customer PagentZ app in staff (read-only)
/// view. Every redirect appends `?orgId=X&staffMode=true` so that the
/// customer-app `StaffModeService` flips into staff mode on boot.
///
/// Defense in depth — even if the URL params slip past, Firestore rules
/// reject any write attempt from a staff session.
class StaffRedirect {
  StaffRedirect._();

  /// Build the URL the customer app should land on. `subPath` is appended
  /// to the customer-app base URL (use `/#/teams`, `/#/incidents`, etc).
  static Uri buildUrl({
    required String orgId,
    String subPath = '/',
    Map<String, String> extraParams = const {},
  }) {
    final base = Uri.parse(AppConfig.pagentzWebUrl);
    final mergedParams = <String, String>{
      ...extraParams,
      'orgId': orgId,
      'staffMode': 'true',
    };

    // Customer app uses hash-routing (#/route). url_launcher doesn't merge
    // query strings into the fragment, so we build the URL by hand to keep
    // the fragment intact.
    final fragment = subPath.startsWith('#') ? subPath.substring(1) : subPath;
    final qs = mergedParams.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    return base.replace(
      fragment: fragment.isEmpty ? '?$qs' : '$fragment?$qs',
    );
  }

  /// Open the customer app in a new browser tab. Audit-logs the redirect
  /// to `staff_audit_logs` so we know which staff member opened which org.
  static Future<void> open({
    required String orgId,
    required String orgName,
    String subPath = '/',
    String? auditAction,
  }) async {
    final url = buildUrl(orgId: orgId, subPath: subPath);

    // Best-effort audit; never block navigation on a logging failure.
    try {
      await AuditLogService.instance.log(
        action: auditAction ?? 'OPENED_CUSTOMER_VIEW',
        targetType: 'org',
        targetId: orgId,
        targetDisplay: orgName,
        changes: {'subPath': subPath},
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('staff redirect audit failed: $e');
      }
    }

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }
}
