import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/staff_user_model.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/staff_auth_service.dart';

class AuthController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final Rxn<StaffUser> currentStaff = Rxn<StaffUser>();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void clearError() => errorMessage.value = '';

  Future<bool> signInWithEmail() async {
    if (isLoading.value) return false;
    isLoading.value = true;
    errorMessage.value = '';

    final result = await StaffAuthService.instance.signInWithEmail(
      emailController.text,
      passwordController.text,
    );

    isLoading.value = false;
    if (!result.success) {
      errorMessage.value = result.errorMessage ?? 'Sign in failed.';
      return false;
    }
    currentStaff.value = result.staff;
    passwordController.clear();
    SessionService.instance.start();
    return true;
  }

  Future<void> signOut() async {
    SessionService.instance.stop();
    await StaffAuthService.instance.signOut();
    currentStaff.value = null;
    emailController.clear();
    passwordController.clear();
  }

  Future<StaffUser?> tryRestoreSession() async {
    final staff = await StaffAuthService.instance.loadCurrentStaff();
    currentStaff.value = staff;
    if (staff != null) {
      SessionService.instance.start();
    }
    return staff;
  }
}
