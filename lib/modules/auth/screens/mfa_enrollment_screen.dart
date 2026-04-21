import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/config/atlas_config.dart';
import '../../../core/services/staff_auth_service.dart';
import '../controller/staff_auth_controller.dart';

class MfaEnrollmentScreen extends StatefulWidget {
  const MfaEnrollmentScreen({super.key});

  @override
  State<MfaEnrollmentScreen> createState() => _MfaEnrollmentScreenState();
}

class _MfaEnrollmentScreenState extends State<MfaEnrollmentScreen> {
  TotpSecret? _secret;
  String? _qrUrl;
  String? _error;
  bool _loading = true;
  bool _submitting = false;
  final _codeCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final session = await user.multiFactor.getSession();
      final secret = await TotpMultiFactorGenerator.generateSecret(session);
      final url = await secret.generateQrCodeUrl(
        accountName: user.email ?? 'staff',
        issuer: AtlasConfig.mfaIssuer,
      );
      setState(() {
        _secret = secret;
        _qrUrl = url;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to start enrollment: $e';
        _loading = false;
      });
    }
  }

  Future<void> _enroll() async {
    if (_secret == null || _codeCtl.text.trim().length < 6) {
      setState(() =>
          _error = 'Enter the 6-digit code from your authenticator app.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final assertion = await TotpMultiFactorGenerator.getAssertionForEnrollment(
        _secret!,
        _codeCtl.text.trim(),
      );
      await user.multiFactor
          .enroll(assertion, displayName: 'Authenticator app');
      await StaffAuthService.instance.markMfaEnrolled(user.uid);
      await StaffAuthService.instance.signOut();
      Get.offAllNamed('/login');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Enrollment failed (${e.code}).';
        _submitting = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unexpected error: $e';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll authenticator'),
        actions: [
          TextButton(
            onPressed: () => Get.find<StaffAuthController>().signOut(),
            child: const Text('Cancel & sign out'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Add this account to Google Authenticator, 1Password, Authy, or any TOTP app.',
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Either paste the otpauth URL below into your password manager, or manually enter the secret into your authenticator app. Then enter the current 6-digit code to finish.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        const Text('otpauth URL',
                            style: TextStyle(color: Colors.white60, fontSize: 11)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  _qrUrl ?? '',
                                  style: const TextStyle(
                                      fontFamily: 'monospace', fontSize: 11),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: 'Copy URL',
                                onPressed: () => Clipboard.setData(
                                    ClipboardData(text: _qrUrl ?? '')),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Secret',
                            style: TextStyle(color: Colors.white60, fontSize: 11)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  _secret?.secretKey ?? '',
                                  style:
                                      const TextStyle(fontFamily: 'monospace'),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: 'Copy secret',
                                onPressed: () => Clipboard.setData(ClipboardData(
                                    text: _secret?.secretKey ?? '')),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _codeCtl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: '6-digit code from authenticator',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(_error!,
                              style: const TextStyle(color: Colors.redAccent)),
                        ],
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _submitting ? null : _enroll,
                          child: _submitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Enroll & sign out'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
