import 'package:get/get.dart';

import '../controllers/daftar_mata_pelajaran_controller.dart';

class DaftarMataPelajaranBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarMataPelajaranController>(
      () => DaftarMataPelajaranController(),
    );
  }
}
