// lib/app/modules/new_password/controllers/new_password_controller.dart (VERSI FINAL & AMAN)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/config_controller.dart';

class NewPasswordController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- TAMBAHAN BARU ---
  final oldPassC = TextEditingController(); 
  final passC = TextEditingController();
  final confirmPassC = TextEditingController();
  final hintC = TextEditingController();
  final isLoading = false.obs;

  // State untuk visibility password
  final isOldPasswordHidden = true.obs;
  final isPasswordHidden = true.obs;
  final isConfirmPasswordHidden = true.obs;

  Future<void> gantiPassword() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) throw Exception("Sesi pengguna tidak valid.");

      // --- PERBAIKAN KRUSIAL: GUNAKAN PASSWORD LAMA DARI INPUT PENGGUNA ---
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!, 
        password: oldPassC.text // Gunakan input dari pengguna, bukan hardcoded
      );
      await user.reauthenticateWithCredential(credential);
      // --- AKHIR PERBAIKAN ---

      String newPassword = passC.text;
      await user.updatePassword(newPassword);
      await user.getIdToken(true);

      await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').doc(user.uid)
          .update({
            'mustChangePassword': false,
            'passwordHint': hintC.text,
            'kelompok' : passC.text,
            });
      
      Get.snackbar('Berhasil', 'Password Anda telah berhasil diperbarui.');
      // Arahkan ke home setelah berhasil
      final newRoute = await configC.decideInitialRoute();
      Get.offAllNamed(newRoute);

    } on FirebaseAuthException catch (e) {
      String msg = "Terjadi kesalahan. Coba lagi.";
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = "Password lama yang Anda masukkan salah.";
      } else if (e.code == 'too-many-requests') {
        msg = "Terlalu banyak percobaan. Coba lagi nanti.";
      }
      Get.snackbar('Gagal', msg, backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Tidak dapat mengubah password: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Validator
  String? validateOldPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password lama tidak boleh kosong.';
    return null;
  }
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password baru tidak boleh kosong.';
    if (value.length < 6) return 'Password minimal 6 karakter.';
    return null;
  }
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Konfirmasi password tidak boleh kosong.';
    if (value != passC.text) return 'Password tidak cocok.';
    return null;
  }
  
  @override
  void onClose() {
    oldPassC.dispose();
    passC.dispose();
    confirmPassC.dispose();
    hintC.dispose();
    super.onClose();
  }
}