import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../utils/routes.dart';
import '../controller/auth_controller.dart';

/// Forces the user to change their password before they can continue.
/// Shown when `passwordExpired()` returns true on their StaffUser doc.
class PasswordRotationScreen extends StatefulWidget {
  const PasswordRotationScreen({super.key});

  @override
  State<PasswordRotationScreen> createState() => _PasswordRotationScreenState();
}

class _PasswordRotationScreenState extends State<PasswordRotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPw = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Not signed in.');
      }

      // Re-authenticate with current password
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: _current.text);
      await user.reauthenticateWithCredential(cred);

      // Update to new password
      await user.updatePassword(_newPw.text);

      // Stamp passwordChangedAt in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'passwordChangedAt': FieldValue.serverTimestamp()},
              SetOptions(merge: true));

      if (!mounted) return;
      Get.offAllNamed(AtlasRoutes.home);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _busy = false;
        _error = _friendly(e);
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Current password is incorrect.';
      case 'weak-password':
        return 'New password is too weak. Use at least 8 characters.';
      case 'requires-recent-login':
        return 'Please sign in again, then change your password.';
      default:
        return e.message ?? 'Failed to update password (${e.code}).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.pageBg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            margin: const EdgeInsets.all(AtlasSpace.xxl),
            padding: const EdgeInsets.all(AtlasSpace.xxl),
            decoration: BoxDecoration(
              color: AtlasColors.cardBg,
              borderRadius: BorderRadius.circular(AtlasRadius.xl),
              border: Border.all(color: AtlasColors.cardBorder),
              boxShadow: AtlasElevation.lg,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AtlasColors.warningSoft,
                        borderRadius: BorderRadius.circular(AtlasRadius.md),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.lock_clock,
                          color: AtlasColors.warning, size: 22),
                    ),
                  ),
                  const SizedBox(height: AtlasSpace.lg),
                  const Text('Time to update your password',
                      style: AtlasText.h2),
                  const SizedBox(height: AtlasSpace.xs),
                  Text(
                    'Your password hasn\'t been changed in over '
                    '${AppConfig.passwordRotationMaxAge.inDays} days. Atlas '
                    'requires regular password rotation for security.',
                    style: AtlasText.smallMuted,
                  ),
                  const SizedBox(height: AtlasSpace.xl),
                  const _Label('Current password'),
                  const SizedBox(height: AtlasSpace.xs + 2),
                  TextFormField(
                    controller: _current,
                    obscureText: true,
                    autofocus: true,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AtlasSpace.md),
                  const _Label('New password'),
                  const SizedBox(height: AtlasSpace.xs + 2),
                  TextFormField(
                    controller: _newPw,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'At least 8 characters',
                    ),
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Min 8 characters';
                      if (v == _current.text) return 'Must differ from current';
                      return null;
                    },
                  ),
                  const SizedBox(height: AtlasSpace.md),
                  const _Label('Confirm new password'),
                  const SizedBox(height: AtlasSpace.xs + 2),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    validator: (v) =>
                        v != _newPw.text ? 'Passwords don\'t match' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AtlasSpace.md),
                    Container(
                      padding: const EdgeInsets.all(AtlasSpace.sm + 2),
                      decoration: BoxDecoration(
                        color: AtlasColors.dangerSoft,
                        borderRadius:
                            BorderRadius.circular(AtlasRadius.sm),
                      ),
                      child: Text(_error!,
                          style: AtlasText.small
                              .copyWith(color: AtlasColors.danger)),
                    ),
                  ],
                  const SizedBox(height: AtlasSpace.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  await Get.find<AuthController>().signOut();
                                  Get.offAllNamed(AtlasRoutes.login);
                                },
                          child: const Text('Sign out'),
                        ),
                      ),
                      const SizedBox(width: AtlasSpace.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Update password'),
                        ),
                      ),
                    ],
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
