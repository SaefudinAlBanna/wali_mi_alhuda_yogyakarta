// lib/app/modules/onboarding/controllers/onboarding_controller.dart (Untuk Aplikasi ORANG TUA)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../controllers/config_controller.dart';
import '../../../models/onboarding_item_model.dart';
import '../../../routes/app_pages.dart';

class OnboardingController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final PageController pageController = PageController();
  final RxInt currentPageIndex = 0.obs;
  final GetStorage _box = GetStorage();

  late List<OnboardingItemModel> onboardingItems;

  @override
  void onInit() {
    super.onInit();
    _loadParentAppOnboardingItems(); // Memuat item spesifik untuk aplikasi Orang Tua
  }

  void _loadParentAppOnboardingItems() {
    onboardingItems = [
      OnboardingItemModel(
        title: "Selamat Datang, Wali Murid MI Al-Huda Yogyakarta!",
        description: "Pantau Progres Belajar Ananda Lebih Dekat. Dapatkan informasi terkini tentang nilai, kehadiran, dan aktivitas akademik putra/putri Anda.",
        imagePath: "assets/lotties/1.json", // Menggunakan aset Anda
        isLottie: true,
      ),
      OnboardingItemModel(
        title: "Informasi Akademik Lengkap",
        description: "Akses Data Akademik Kapan Saja. Lihat riwayat nilai, jadwal pelajaran, pengumuman tugas, dan progres setoran halaqah Ananda secara real-time.",
        imagePath: "assets/lotties/2.json", // Menggunakan aset Anda
        isLottie: true,
      ),
      OnboardingItemModel(
        title: "Komunikasi & Notifikasi Instan",
        description: "Terhubung dengan Sekolah Lebih Mudah. Terima pengumuman penting, info kegiatan sekolah, dan kirim catatan kepada pengampu halaqah Ananda.",
        imagePath: "assets/lotties/3.json", // Menggunakan aset Anda
        isLottie: true,
      ),
      OnboardingItemModel(
        title: "Mewujudkan Generasi Qur'ani Bersama",
        description: "Kami berkomitmen untuk pendidikan terbaik. Bersama, kita bimbing Ananda mencapai potensi maksimal.",
        imagePath: "assets/lotties/4.json", // Menggunakan aset Anda
        isLottie: true,
      ),
    ];
  }

  void onPageChanged(int index) {
    currentPageIndex.value = index;
  }

  void onNext() {
    if (currentPageIndex.value < onboardingItems.length - 1) {
      pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      _finishOnboarding();
    }
  }

  void onSkip() {
    _finishOnboarding();
  }

  void _finishOnboarding() async {
    await _box.write('hasSeenOnboarding', true);
    // Navigasi ke Splash screen aplikasi Orang Tua
    Get.offAllNamed(Routes.SPLASH);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}