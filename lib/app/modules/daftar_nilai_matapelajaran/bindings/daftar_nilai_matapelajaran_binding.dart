import 'package:get/get.dart';

import '../controllers/daftar_nilai_matapelajaran_controller.dart';

class DaftarNilaiMatapelajaranBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarNilaiMatapelajaranController>(
      () => DaftarNilaiMatapelajaranController(),
    );
  }
}
