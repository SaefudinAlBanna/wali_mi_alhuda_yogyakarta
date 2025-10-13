import 'package:get/get.dart';

import '../controllers/laporan_komite_controller.dart';

class LaporanKomiteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LaporanKomiteController>(
      () => LaporanKomiteController(),
    );
  }
}
