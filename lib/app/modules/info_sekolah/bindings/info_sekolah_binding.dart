import 'package:get/get.dart';

import '../controllers/info_sekolah_controller.dart';

class InfoSekolahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InfoSekolahController>(
      () => InfoSekolahController(),
    );
  }
}
