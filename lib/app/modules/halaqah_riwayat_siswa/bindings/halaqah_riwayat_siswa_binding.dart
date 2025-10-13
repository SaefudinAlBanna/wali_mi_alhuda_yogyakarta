import 'package:get/get.dart';

import '../controllers/halaqah_riwayat_siswa_controller.dart';

class HalaqahRiwayatSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahRiwayatSiswaController>(
      () => HalaqahRiwayatSiswaController(),
    );
  }
}
