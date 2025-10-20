import 'package:get/get.dart';

import '../controllers/manajemen_komite_sekolah_controller.dart';

class ManajemenKomiteSekolahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenKomiteSekolahController>(
      () => ManajemenKomiteSekolahController(),
    );
  }
}
