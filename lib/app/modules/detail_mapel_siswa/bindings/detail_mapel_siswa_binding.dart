import 'package:get/get.dart';

import '../controllers/detail_mapel_siswa_controller.dart';

class DetailMapelSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DetailMapelSiswaController>(
      () => DetailMapelSiswaController(),
    );
  }
}
