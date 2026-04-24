import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../utils/routes.dart';
import '../controller/auth_controller.dart';

/// TOTP (authenticator app) enrollment screen. Uses Firebase Auth multi-factor
/// support. Prompts the user to install an authenticator app, scan the QR
/// (or enter the shared secret manually), then enter a 6-digit code to verify.
///
/// Availability note: Firebase Auth TOTP requires Firebase Identity Platform.
/// If you haven't enabled that yet, this screen will show instructions.
class MfaEnrollmentScreen extends StatefulWidget {
  const MfaEnrollmentScreen({super.key});

  @override
  State<MfaEnrollmentScreen> createState() => _MfaEnrollmentScreenState();
}

class _MfaEnrollmentScreenState extends State<MfaEnrollmentScreen> {
  final _codeController = TextEditingController();
  bool _loading = true;
  bool _verifying = false;
  String? _secret;
  String? _error;
  TotpSecret? _totpSecret;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) Get.offAllNamed(AtlasRoutes.login);
        return;
      }
      final session = await user.multiFactor.getSession();
      final secret = await TotpMultiFactorGenerator.generateSecret(session);
      setState(() {
        _totpSecret = secret;
        _secret = secret.secretKey;
        _loading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _error =
            'Could not start TOTP enrollment: ${e.message ?? e.code}. '
            'Make sure Firebase Identity Platform is enabled with MFA.';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (_totpSecret == null || code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your authenticator.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final assertion = await TotpMultiFactorGenerator
          .getAssertionForEnrollment(_totpSecret!, code);
      final user = FirebaseAuth.instance.currentUser!;
      await user.multiFactor.enroll(assertion, displayName: 'Authenticator');

      // Stamp mfaEnrolled in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'mfaEnrolled': true}, SetOptions(merge: true));

      if (!mounted) return;
      Get.snackbar(
        'MFA enabled',
        'From now on, sign-ins will require your authenticator code.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AtlasColors.successSoft,
        colorText: AtlasColors.success,
        margin: const EdgeInsets.all(16),
      );
      Get.offAllNamed(AtlasRoutes.home);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _verifying = false;
        _error = e.message ?? 'Verification failed (${e.code}).';
      });
    } catch (e) {
      setState(() {
        _verifying = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.pageBg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            margin: const EdgeInsets.all(AtlasSpace.xxl),
            padding: const EdgeInsets.all(AtlasSpace.xxl),
            decoration: BoxDecoration(
              color: AtlasColors.cardBg,
              borderRadius: BorderRadius.circular(AtlasRadius.xl),
              border: Border.all(color: AtlasColors.cardBorder),
              boxShadow: AtlasElevation.lg,
            ),
            child: _loading ? _buildLoading() : _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AtlasSpace.huge),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AtlasColors.accentSoft,
              borderRadius: BorderRadius.circular(AtlasRadius.md),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.security, color: AtlasColors.accent, size: 22),
          ),
        ),
        const SizedBox(height: AtlasSpace.lg),
        const Text('Set up two-factor authentication', style: AtlasText.h2),
        const SizedBox(height: AtlasSpace.xs),
        const Text(
          'Atlas protects staff access with a second factor. Install an '
          'authenticator app (1Password, Authy, Google Authenticator), '
          'then scan the code or enter the key below.',
          style: AtlasText.smallMuted,
        ),
        const SizedBox(height: AtlasSpace.xl),

        if (_secret != null) _secretBox(_secret!),
        const SizedBox(height: AtlasSpace.xl),

        const _Label('Enter the 6-digit code'),
        const SizedBox(height: AtlasSpace.xs + 2),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 8,
          ),
          decoration: const InputDecoration(hintText: '000000'),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),

        if (_error != null) ...[
          const SizedBox(height: AtlasSpace.md),
          Container(
            padding: const EdgeInsets.all(AtlasSpace.sm + 2),
            decoration: BoxDecoration(
              color: AtlasColors.dangerSoft,
              borderRadius: BorderRadius.circular(AtlasRadius.sm),
            ),
            child: Text(_error!,
                style: AtlasText.small.copyWith(color: AtlasColors.danger)),
          ),
        ],

        const SizedBox(height: AtlasSpace.xl),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _verifying
                    ? null
                    : () async {
                        await Get.find<AuthController>().signOut();
                        Get.offAllNamed(AtlasRoutes.login);
                      },
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AtlasSpace.md),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _verifying || _totpSecret == null ? null : _verify,
                child: _verifying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verify & enable'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _secretBox(String secret) {
    // Chunked display for manual entry
    final chunks = <String>[];
    for (var i = 0; i < secret.length; i += 4) {
      chunks.add(secret.substring(i, (i + 4).clamp(0, secret.length)));
    }
    final formatted = chunks.join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Label('Enter this key into your authenticator app'),
        const SizedBox(height: AtlasSpace.xs + 2),
        Container(
          padding: const EdgeInsets.all(AtlasSpace.md),
          decoration: BoxDecoration(
            color: AtlasColors.pageBg,
            border: Border.all(color: AtlasColors.cardBorder),
            borderRadius: BorderRadius.circular(AtlasRadius.sm),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  formatted,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: AtlasColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                iconSize: 16,
                icon: const Icon(Icons.copy_rounded),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: secret));
                  Get.snackbar('Copied', 'Secret copied to clipboard.',
                      snackPosition: SnackPosition.BOTTOM);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AtlasColors.textPrimary,
      ),
    );
  }
}
