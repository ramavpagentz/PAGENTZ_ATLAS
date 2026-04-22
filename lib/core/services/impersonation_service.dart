import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../config/app_config.dart';
import '../models/impersonation_session_model.dart';
import '../../utils/web_download_stub.dart'
    if (dart.library.html) '../../utils/web_download_web.dart';

class ImpersonationResult {
  final bool ok;
  final String? errorMessage;
  final String? sessionId;
  const ImpersonationResult.success(this.sessionId)
      : ok = true,
        errorMessage = null;
  const ImpersonationResult.failed(this.errorMessage)
      : ok = false,
        sessionId = null;
}

class ImpersonationService {
  ImpersonationService._();
  static final instance = ImpersonationService._();

  final _functions = FirebaseFunctions.instance;
  final _db = FirebaseFirestore.instance;

  /// Calls the `atlasImpersonate` Cloud Function and opens the customer app
  /// in a new browser tab with the minted token as a URL parameter.
  Future<ImpersonationResult> startSession({
    required String orgId,
    required String targetUid,
    required String reason,
    required ImpersonationMode mode,
    required int durationMinutes,
  }) async {
    try {
      final callable = _functions.httpsCallable('atlasImpersonate');
      final result = await callable.call({
        'targetOrgId': orgId,
        'targetUid': targetUid,
        'reason': reason,
        'mode': mode.id,
        'durationMinutes': durationMinutes,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final token = data['token'] as String?;
      final sessionId = data['sessionId'] as String?;
      if (token == null) {
        return const ImpersonationResult.failed('No token returned.');
      }
      // Open the customer app in a new tab with the impersonation token.
      final url = '${AppConfig.pagentzWebUrl}'
          '?atlas_impersonation_token=$token'
          '&atlas_session=$sessionId'
          '&atlas_mode=${mode.id}';
      openUrlInNewTab(url);
      return ImpersonationResult.success(sessionId);
    } on FirebaseFunctionsException catch (e) {
      return ImpersonationResult.failed(e.message ?? e.code);
    } catch (e) {
      return ImpersonationResult.failed(e.toString());
    }
  }

  /// All sessions for an org (most recent first). Used in customer detail.
  Stream<List<ImpersonationSession>> watchSessionsForOrg(String orgId) {
    return _db
        .collection('impersonation_sessions')
        .where('targetOrgId', isEqualTo: orgId)
        .orderBy('startedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(ImpersonationSession.fromFirestore).toList());
  }
}
