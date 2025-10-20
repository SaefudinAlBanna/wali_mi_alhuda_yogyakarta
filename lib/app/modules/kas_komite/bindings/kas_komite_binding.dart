import 'package:get/get.dart';

import '../controllers/kas_komite_controller.dart';

class KasKomiteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<KasKomiteController>(
      () => KasKomiteController(),
    );
  }
}
