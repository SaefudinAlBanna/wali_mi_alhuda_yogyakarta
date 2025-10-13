// lib/app/modules/account_switcher/controllers/account_switcher_controller.dart

import 'package:get/get.dart';
import '../../../controllers/account_manager_controller.dart'; 
import '../../../models/student_profile_preview_model.dart';
import '../../../routes/app_pages.dart'; // [FIXED]: Ensure import is here

class AccountSwitcherController extends GetxController {
  final AccountManagerController _accountManager = Get.find<AccountManagerController>();

  Rxn<StudentProfilePreview> get currentActiveStudent => _accountManager.currentActiveStudent;
  // [FIXED]: Correct return type to RxList
  RxList<StudentProfilePreview> get storedStudentAccounts => _accountManager.storedStudentAccounts; 
  RxBool get isProcessingAccount => _accountManager.isProcessingAccount;

  Future<void> switchStudentAccount(String uid) => _accountManager.switchStudentAccount(uid);
  Future<void> removeStudentAccount(String uid) => _accountManager.removeStudentAccount(uid);
  Future<void> logoutAllAccounts() => _accountManager.logoutAllAccounts();

  void goToLoginToAddAccount() {
    Get.toNamed(Routes.LOGIN, arguments: {'isAddingAccount': true});
  }
}