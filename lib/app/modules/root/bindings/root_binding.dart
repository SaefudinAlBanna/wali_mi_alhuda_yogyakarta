// lib/app/modules/root/bindings/root_binding.dart

import 'package:get/get.dart';

class RootBinding extends Bindings {
  @override
  void dependencies() {
    // Tidak ada dependensi yang perlu didaftarkan di sini lagi.
    // Splash, Login, dan Home akan diurus oleh binding mereka sendiri
    // atau oleh Get.put() saat dibutuhkan.
  }
}