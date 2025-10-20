// lib/main.dart

import 'package:firebase_core/firebase_core.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'app/controllers/storage_controller.dart';

import 'app/controllers/account_manager_controller.dart'; 
import 'app/services/auth_secure_storage_service.dart'; 
import 'app/controllers/auth_controller.dart';
import 'app/controllers/config_controller.dart';
import 'app/modules/home/controllers/home_controller.dart';
import 'app/modules/home/controllers/profile_controller.dart';
import 'app/routes/app_pages.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await supabase.Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await GetStorage.init();
  await initializeDateFormatting('id_ID', null);

  // Daftarkan service dan controller permanent
  // Urutan yang benar untuk menghindari circular dependency di constructor/onInit
  Get.put(AuthSecureStorageService(), permanent: true); // Paling dasar, tidak ada dependencies di constructor

  // Karena ConfigController dan AccountManagerController sekarang
  // sama-sama memindahkan Get.find() ke onInit(), urutan Get.put() mereka 
  // menjadi kurang kritikal dalam konteks circular dependency.
  // Ini adalah urutan yang aman:
  Get.put(ConfigController(), permanent: true);
  Get.put(AccountManagerController(), permanent: true);

  // Controller lain yang tidak memiliki circular dependency atau dependen pada yang di atas.
  Get.put(AuthController(), permanent: true);
  Get.put(StorageController(), permanent: true);
  Get.put(HomeController(), permanent: true);
  Get.put(ProfileController(), permanent: true);

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Wali MI Al-Huda",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    ),
  );
}