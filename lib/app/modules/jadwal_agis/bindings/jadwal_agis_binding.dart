import 'package:get/get.dart';

import '../controllers/jadwal_agis_controller.dart';

class JadwalAgisBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JadwalAgisController>(
      () => JadwalAgisController(),
    );
  }
}
