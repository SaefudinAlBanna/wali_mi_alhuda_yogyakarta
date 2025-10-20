import 'package:get/get.dart';

import '../controllers/input_jadwal_agis_controller.dart';

class InputJadwalAgisBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InputJadwalAgisController>(
      () => InputJadwalAgisController(),
    );
  }
}
