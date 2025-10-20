// lib/app/modules/root/views/root_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Kita tidak lagi memerlukan ConfigController di sini
// import 'package:aplikasi_orangtua/app/controllers/config_controller.dart';

// Kita juga tidak lagi memanggil halaman lain dari sini
// import 'package:aplikasi_orangtua/app/modules/home/views/home_view.dart';
// import 'package:aplikasi_orangtua/app/modules/login/views/login_view.dart';

// GetView tidak lagi diperlukan karena kita tidak butuh controller
class RootView extends StatelessWidget {
  const RootView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // RootView sekarang hanya menjadi placeholder loading awal
    // sebelum SplashController mengambil alih.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}