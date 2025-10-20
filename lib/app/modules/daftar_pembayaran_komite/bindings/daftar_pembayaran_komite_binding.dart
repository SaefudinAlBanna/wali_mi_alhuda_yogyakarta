import 'package:get/get.dart';

import '../controllers/daftar_pembayaran_komite_controller.dart';

class DaftarPembayaranKomiteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarPembayaranKomiteController>(
      () => DaftarPembayaranKomiteController(),
    );
  }
}
