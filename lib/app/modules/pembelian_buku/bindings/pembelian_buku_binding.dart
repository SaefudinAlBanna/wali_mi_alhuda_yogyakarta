import 'package:get/get.dart';

import '../controllers/pembelian_buku_controller.dart';

class PembelianBukuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PembelianBukuController>(
      () => PembelianBukuController(),
    );
  }
}
