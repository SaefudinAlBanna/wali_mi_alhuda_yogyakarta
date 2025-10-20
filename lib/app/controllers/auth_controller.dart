// lib/app/controllers/auth_controller.dart (VERSI FINAL & STABIL UNTUK ORANG TUA)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/account_manager_controller.dart'; 
import '../modules/home/controllers/home_controller.dart'; 
import '../modules/info_sekolah_list/controllers/info_sekolah_list_controller.dart'; 
import '../routes/app_pages.dart'; 

class AuthController extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final RxBool isLoading = false.obs;
  final AccountManagerController _accountManager = Get.find<AccountManagerController>();

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      UserCredential userCredential = await auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
      
      await _accountManager.addOrSwitchLoggedInStudent(email.trim(), password.trim());

      // [PERBAIKAN KRUSIAL]: Tambahkan navigasi ini kembali!
      // Setelah login Firebase Auth berhasil DAN akun disimpan/diganti,
      // kita harus menavigasi ke Splash untuk alur penentuan rute.
      Get.offAllNamed(Routes.SPLASH); 

    } on FirebaseAuthException catch (e) {
      String msg = "Gagal login. Periksa kembali email dan password Anda.";
      if (e.code == 'user-not-found') msg = "Email tidak terdaftar.";
      if (e.code == 'wrong-password') msg = "Password yang Anda masukkan salah.";
      Get.snackbar("Gagal Login", msg, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan yang tidak diketahui.", snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      
      if (Get.isRegistered<HomeController>()) {
        Get.delete<HomeController>(force: true);
      }
      if (Get.isRegistered<InfoSekolahListController>()) {
        Get.delete<InfoSekolahListController>(force: true);
      }

      await auth.signOut();
      await _accountManager.clearActiveStudent(); 

      Get.offAllNamed(Routes.LOGIN); 
    } catch (e) {
      Get.snackbar("Error", "Gagal untuk logout. Silakan coba lagi.", snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}