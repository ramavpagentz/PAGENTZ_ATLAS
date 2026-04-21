import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/staff_auth_controller.dart';

class MfaChallengeScreen extends StatefulWidget {
  const MfaChallengeScreen({super.key});

  @override
  State<MfaChallengeScreen> createState() => _MfaChallengeScreenState();
}

class _MfaChallengeScreenState extends State<MfaChallengeScreen> {
  final _codeCtl = TextEditingController();
  String? _error;
  bool _submitting = false;

  Future<void> _submit() async {
    final c = Get.find<StaffAuthController>();
    final resolver = c.pendingMfaResolver;
    if (resolver == null) {
      Get.offAllNamed('/login');
      return;
    }
    if (_codeCtl.text.trim().length < 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final totpHint = resolver.hints.whereType<TotpMultiFactorInfo>().firstOrNull
        ?? resolver.hints.firstOrNull;
    if (totpHint == null) {
      setState(() {
        _submitting = false;
        _error = 'No MFA factor enrolled on this account.';
      });
      return;
    }

    try {
      final assertion = await TotpMultiFactorGenerator.getAssertionForSignIn(
        totpHint.uid,
        _codeCtl.text.trim(),
      );
      await resolver.resolveSignIn(assertion);
      c.pendingMfaResolver = null;
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Challenge failed (${e.code}).';
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Two-factor authentication',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the 6-digit code from your authenticator app.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _codeCtl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify'),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.find<StaffAuthController>().pendingMfaResolver = null;
                      Get.offAllNamed('/login');
                    },
                    child: const Text('Back to sign-in'),
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
