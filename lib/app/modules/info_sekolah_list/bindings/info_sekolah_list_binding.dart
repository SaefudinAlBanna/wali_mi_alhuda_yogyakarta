import 'package:get/get.dart';

import '../controllers/info_sekolah_list_controller.dart';

class InfoSekolahListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InfoSekolahListController>(
      () => InfoSekolahListController(),
    );
  }
}
