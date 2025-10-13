import 'package:get/get.dart';

import '../controllers/halaqah_ummi_riwayat_siswa_controller.dart';

class HalaqahUmmiRiwayatSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalaqahUmmiRiwayatSiswaController>(
      () => HalaqahUmmiRiwayatSiswaController(),
    );
  }
}
