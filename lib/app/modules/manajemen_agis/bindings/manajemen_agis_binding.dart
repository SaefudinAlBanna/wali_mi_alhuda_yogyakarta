import 'package:get/get.dart';

import '../controllers/manajemen_agis_controller.dart';

class ManajemenAgisBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenAgisController>(
      () => ManajemenAgisController(),
    );
  }
}
