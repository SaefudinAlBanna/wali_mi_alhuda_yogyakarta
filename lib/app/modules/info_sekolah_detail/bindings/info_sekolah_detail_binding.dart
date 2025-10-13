import 'package:get/get.dart';

// Import controller yang dibutuhkan
import '../../info_sekolah_list/controllers/info_sekolah_list_controller.dart';

class InfoSekolahDetailBinding extends Bindings {
  @override
  void dependencies() {
    // --- [PERBAIKAN UTAMA] ---
    // Daftarkan controller di sini. Ini akan memastikan controller selalu tersedia
    // saat InfoSekolahDetailView dibangun, tidak peduli dari mana asalnya.
    Get.lazyPut<InfoSekolahListController>(
      () => InfoSekolahListController(),
    );
    // ----------------------------
  }
}