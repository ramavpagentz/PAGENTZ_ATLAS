// ──────────────────────────────────────────────────────────────────────────
// ATLAS IMPERSONATION HANDLER — copy into the main PagentZ Flutter app.
//
// What this does:
//   1. On app startup, checks the URL for `?atlas_impersonation_token=XXX`
//   2. If found, signs in to Firebase Auth using that custom token
//   3. Shows a persistent red banner: "VIEWING AS [user] · Staff: [email] · ends in MM:SS"
//   4. Optionally blocks all write actions if mode == read_only
//   5. Auto-signs-out when expiresAt passes
//
// Where to put this:
//   - Copy to: /lib/core/services/atlas_impersonation_handler.dart in the main pagentz repo
//   - Initialize in main_app.dart after Firebase init:
//
//     void main() async {
//       ...
//       await Firebase.initializeApp(...);
//       await AtlasImpersonationHandler.instance.checkUrlForToken(); // NEW
//       runApp(const MainApp());
//     }
//
//   - Wrap your top-level app widget with the banner:
//
//     MaterialApp(
//       builder: (context, child) => AtlasImpersonationBanner(child: child!),
//       home: ...,
//     )
// ──────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AtlasImpersonationHandler {
  AtlasImpersonationHandler._();
  static final instance = AtlasImpersonationHandler._();

  bool _active = false;
  String? _sessionId;
  String? _mode;          // "read_only" | "read_write"
  DateTime? _expiresAt;
  String? _staffEmail;    // populated after sign-in via custom claims

  bool get isActive => _active;
  bool get isReadOnly => _mode == 'read_only';
  String? get sessionId => _sessionId;
  String? get staffEmail => _staffEmail;
  DateTime? get expiresAt => _expiresAt;

  /// Call once at app startup, before runApp. Web-only — no-op on mobile.
  Future<void> checkUrlForToken() async {
    if (!kIsWeb) return;
    final uri = Uri.base;
    final token = uri.queryParameters['atlas_impersonation_token'];
    if (token == null || token.isEmpty) return;

    _sessionId = uri.queryParameters['atlas_session'];
    _mode = uri.queryParameters['atlas_mode'] ?? 'read_only';

    try {
      final cred = await FirebaseAuth.instance.signInWithCustomToken(token);
      final claims = (await cred.user?.getIdTokenResult())?.claims ?? {};
      final exp = claims['expiresAt'];
      if (exp is int) {
        _expiresAt = DateTime.fromMillisecondsSinceEpoch(exp);
      } else {
        _expiresAt = DateTime.now().add(const Duration(hours: 1));
      }
      _staffEmail = claims['impersonatedBy']?.toString();
      _active = true;
    } catch (e) {
      debugPrint('Atlas impersonation token sign-in failed: $e');
    }
  }

  /// Call to manually end the session.
  Future<void> endSession() async {
    _active = false;
    await FirebaseAuth.instance.signOut();
  }
}

/// Persistent banner shown at the top of the screen during impersonation.
/// Wrap your MaterialApp's `builder` with this.
class AtlasImpersonationBanner extends StatefulWidget {
  final Widget child;
  const AtlasImpersonationBanner({super.key, required this.child});

  @override
  State<AtlasImpersonationBanner> createState() => _AtlasImpersonationBannerState();
}

class _AtlasImpersonationBannerState extends State<AtlasImpersonationBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (AtlasImpersonationHandler.instance.isActive) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final exp = AtlasImpersonationHandler.instance.expiresAt;
        if (exp != null && DateTime.now().isAfter(exp)) {
          AtlasImpersonationHandler.instance.endSession();
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = AtlasImpersonationHandler.instance;
    if (!h.isActive) return widget.child;

    final remaining = h.expiresAt?.difference(DateTime.now()) ?? Duration.zero;
    final mins = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Column(
      children: [
        Material(
          color: const Color(0xFFDC2626),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          const Text('STAFF VIEWING AS YOU'),
                          if (h.staffEmail != null)
                            Text(
                              '· ${h.staffEmail}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              h.isReadOnly ? 'READ-ONLY' : 'READ-WRITE',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                          Text(
                            '· ends in $mins:$secs',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await AtlasImpersonationHandler.instance.endSession();
                      if (mounted) setState(() {});
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    child: const Text(
                      'End session',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Helper for write-action gating in the customer app. Call before any
/// destructive/mutating UI action:
///
///   if (!AtlasImpersonationGuard.allowWrite(context)) return;
class AtlasImpersonationGuard {
  static bool allowWrite(BuildContext context) {
    final h = AtlasImpersonationHandler.instance;
    if (!h.isActive) return true;        // not impersonating — allow
    if (!h.isReadOnly) return true;      // read-write mode — allow
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFFDC2626),
        content: Text(
          'Write blocked: this is a read-only impersonation session.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
    return false;
  }
}
