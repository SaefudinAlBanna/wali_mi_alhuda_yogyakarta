import 'package:get/get.dart';

import '../controllers/daftar_spp_controller.dart';

class DaftarSppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarSppController>(
      () => DaftarSppController(),
    );
  }
}
