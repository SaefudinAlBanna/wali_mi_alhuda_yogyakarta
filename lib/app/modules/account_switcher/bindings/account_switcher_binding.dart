import 'package:get/get.dart';
import '../controllers/account_switcher_controller.dart'; // Ini akan menjadi alias untuk AccountManagerController

class AccountSwitcherBinding extends Bindings {
  @override
  void dependencies() {
    // AccountManagerController sudah di-put permanent di main.dart
    // Jadi di sini cukup Get.find()
    Get.lazyPut<AccountSwitcherController>(
      () => AccountSwitcherController(), // Gunakan controller ini untuk UI switcher
    );
  }
}