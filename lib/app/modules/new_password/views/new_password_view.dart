// lib/app/modules/new_password/views/new_password_view.dart (VERSI FINAL & AMAN)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/new_password_controller.dart';

class NewPasswordView extends GetView<NewPasswordController> {
  const NewPasswordView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Password Baru'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Keamanan Akun", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text("Untuk melanjutkan, masukkan password lama Anda (password default: telagailmu) dan buat password baru.", style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                const SizedBox(height: 40),

                // --- FIELD BARU: PASSWORD LAMA ---
                Obx(() => TextFormField(
                  controller: controller.oldPassC,
                  obscureText: controller.isOldPasswordHidden.value,
                  decoration: InputDecoration(
                    labelText: "Password Lama",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(controller.isOldPasswordHidden.value ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => controller.isOldPasswordHidden.toggle(),
                    ),
                  ),
                  validator: controller.validateOldPassword,
                )),
                const SizedBox(height: 24),

                // Password Baru
                Obx(() => TextFormField(
                  controller: controller.passC,
                  obscureText: controller.isPasswordHidden.value,
                  decoration: InputDecoration(
                    labelText: "Password Baru",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(controller.isPasswordHidden.value ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => controller.isPasswordHidden.toggle(),
                    ),
                  ),
                  validator: controller.validatePassword,
                )),
                const SizedBox(height: 16),

                // Konfirmasi Password Baru
                Obx(() => TextFormField(
                  controller: controller.confirmPassC,
                  obscureText: controller.isConfirmPasswordHidden.value,
                  decoration: InputDecoration(
                    labelText: "Konfirmasi Password Baru",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(controller.isConfirmPasswordHidden.value ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => controller.isConfirmPasswordHidden.toggle(),
                    ),
                  ),
                  validator: controller.validateConfirmPassword,
                )),
                const SizedBox(height: 16),
                TextFormField( // <-- TAMBAHKAN BLOK INI
                  controller: controller.hintC,
                  decoration: const InputDecoration(
                    labelText: "Petunjuk Password (Hint)",
                    hintText: "Contoh: Nama hewan peliharaan",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text( // <-- TAMBAHKAN BLOK INI
                  "Hint ini akan membantu Anda jika lupa password. Jangan tulis password Anda di sini.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 32),
                
                Obx(() => ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: controller.isLoading.value ? null : controller.gantiPassword,
                  child: Text(controller.isLoading.value ? 'MENYIMPAN...' : 'SIMPAN PASSWORD BARU'),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}