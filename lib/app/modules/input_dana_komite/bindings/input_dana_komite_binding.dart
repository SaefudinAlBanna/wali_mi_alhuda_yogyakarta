import 'package:get/get.dart';

import '../controllers/input_dana_komite_controller.dart';

class InputDanaKomiteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InputDanaKomiteController>(
      () => InputDanaKomiteController(),
    );
  }
}
