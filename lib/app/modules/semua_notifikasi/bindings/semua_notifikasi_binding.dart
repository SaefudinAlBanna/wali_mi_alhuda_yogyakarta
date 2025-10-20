import 'package:get/get.dart';

import '../controllers/semua_notifikasi_controller.dart';

class SemuaNotifikasiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SemuaNotifikasiController>(
      () => SemuaNotifikasiController(),
    );
  }
}
