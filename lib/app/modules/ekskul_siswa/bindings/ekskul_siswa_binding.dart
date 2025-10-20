import 'package:get/get.dart';

import '../controllers/ekskul_siswa_controller.dart';

class EkskulSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EkskulSiswaController>(
      () => EkskulSiswaController(),
    );
  }
}
