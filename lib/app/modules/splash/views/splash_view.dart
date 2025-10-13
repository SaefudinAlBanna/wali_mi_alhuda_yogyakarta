// lib/app/modules/splash/views/splash_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Panggil controller agar onReady() berjalan
    Get.put(SplashController());

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // FlutterLogo(size: 100),
            SizedBox(
                      height: 100,
                      width: 100,
                      child: Image.asset("assets/png/logo.png"),
                    ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text("Memverifikasi sesi..."),
          ],
        ),
      ),
    );
  }
}