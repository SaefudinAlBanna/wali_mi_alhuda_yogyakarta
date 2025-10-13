// lib/app/modules/splash/controllers/splash_controller.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../controllers/account_manager_controller.dart'; 
import '../../../controllers/config_controller.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final AccountManagerController _accountManager = Get.find<AccountManagerController>(); 
  final FirebaseAuth _auth = FirebaseAuth.instance; 
  final GetStorage _box = GetStorage(); 

  @override
  void onReady() {
    super.onReady();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(seconds: 2)); 

    final bool hasSeenOnboarding = _box.read('hasSeenOnboarding') ?? false;

    if (!hasSeenOnboarding) {
      Get.offAllNamed(Routes.ONBOARDING);
      return;
    }

    final activeStudent = _accountManager.currentActiveStudent.value;

    if (activeStudent == null) {
      print("👋 [SplashController] No active student found. Navigating to LOGIN.");
      Get.offAllNamed(Routes.LOGIN);
      return;
    }

    print("🚀 [SplashController] Attempting auto-login for active student: ${activeStudent.namaLengkap} (${activeStudent.uid})");
    try {
      await _auth.signInWithEmailAndPassword(
        email: activeStudent.email,
        password: activeStudent.passwordEncrypted, 
      );
      print("✅ [SplashController] Auto-login successful for ${activeStudent.namaLengkap}.");
      final String initialRoute = await configC.decideInitialRoute();
      Get.offAllNamed(initialRoute);
    } on FirebaseAuthException catch (e) {
      print("❌ [SplashController] Auto-login failed for ${activeStudent.namaLengkap}: ${e.code} - ${e.message}");
      Get.snackbar("Sesi Berakhir", "Sesi login Anda sudah berakhir. Silakan login kembali.", backgroundColor: Colors.red, colorText: Colors.white);
      await _accountManager.clearActiveStudent(); // [FIXED]: Memanggil method yang sudah ada
      Get.offAllNamed(Routes.LOGIN); 
    } catch (e) {
      print("❌ [SplashController] General error during auto-login: $e");
      Get.snackbar("Error Sesi", "Terjadi kesalahan saat memuat sesi. Silakan login kembali.", backgroundColor: Colors.red, colorText: Colors.white);
      await _accountManager.clearActiveStudent(); // [FIXED]: Memanggil method yang sudah ada
      Get.offAllNamed(Routes.LOGIN);
    }
  }
}