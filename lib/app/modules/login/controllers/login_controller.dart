// lib/app/modules/login/controllers/login_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/account_manager_controller.dart'; 

class LoginController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  final AccountManagerController _accountManager = Get.find<AccountManagerController>(); 
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool isPasswordHidden = true.obs;
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();

  bool isAddingAccount = false; 

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is Map && Get.arguments['isAddingAccount'] == true) {
      isAddingAccount = true;
      Get.snackbar("Tambah Akun", "Silakan masukkan kredensial anak yang ingin ditambahkan.", snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
    }
  }

  void login() async {
    if (formKey.currentState!.validate()) {
      await authController.login(emailC.text, passC.text);
    }
  }
  
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email tidak boleh kosong.';
    if (!GetUtils.isEmail(value)) return 'Format email tidak valid.';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password tidak boleh kosong.';
    return null;
  }

  @override
  void onClose() {
    print("🗑️ [LoginController] onClose called.");
    emailC.dispose();
    passC.dispose();
    super.onClose();
  }
}