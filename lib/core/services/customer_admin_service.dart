import 'package:cloud_functions/cloud_functions.dart';

class AdminActionResult {
  final bool ok;
  final String? errorMessage;
  const AdminActionResult.success()
      : ok = true,
        errorMessage = null;
  const AdminActionResult.failed(this.errorMessage) : ok = false;
}

/// Wraps the customer-admin Cloud Functions (reset password, revoke sessions,
/// disable account). Each Cloud Function performs its own RBAC check + writes
/// to the audit log atomically.
class CustomerAdminService {
  CustomerAdminService._();
  static final instance = CustomerAdminService._();

  final _functions = FirebaseFunctions.instance;

  Future<AdminActionResult> sendPasswordReset({
    required String userUid,
    required String userEmail,
    required String reason,
  }) async {
    return _call('atlasResetCustomerPassword', {
      'targetUid': userUid,
      'targetEmail': userEmail,
      'reason': reason,
    });
  }

  Future<AdminActionResult> revokeSessions({
    required String userUid,
    required String userEmail,
    required String reason,
  }) async {
    return _call('atlasRevokeCustomerSessions', {
      'targetUid': userUid,
      'targetEmail': userEmail,
      'reason': reason,
    });
  }

  Future<AdminActionResult> setOrgDisabled({
    required String orgId,
    required String orgName,
    required bool disabled,
    required String reason,
  }) async {
    return _call('atlasSetOrgDisabled', {
      'orgId': orgId,
      'orgName': orgName,
      'disabled': disabled,
      'reason': reason,
    });
  }

  Future<AdminActionResult> _call(String name, Map<String, dynamic> data) async {
    try {
      await _functions.httpsCallable(name).call(data);
      return const AdminActionResult.success();
    } on FirebaseFunctionsException catch (e) {
      return AdminActionResult.failed(e.message ?? e.code);
    } catch (e) {
      return AdminActionResult.failed(e.toString());
    }
  }
}
