// lib/app/modules/onboarding/views/onboarding_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../models/onboarding_item_model.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: controller.pageController,
            itemCount: controller.onboardingItems.length,
            onPageChanged: controller.onPageChanged,
            itemBuilder: (context, index) {
              final item = controller.onboardingItems[index];
              return _OnboardingPage(item: item);
            },
          ),
          Positioned(
            bottom: 30.0,
            left: 20.0,
            right: 20.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Row(
                  children: List.generate(
                    controller.onboardingItems.length,
                    (index) => _buildDot(index, controller.currentPageIndex.value),
                  ),
                )),
                Obx(() {
                  final isLastPage = controller.currentPageIndex.value == controller.onboardingItems.length - 1;
                  return Row(
                    children: [
                      if (!isLastPage)
                        TextButton(
                          onPressed: controller.onSkip,
                          child: const Text("Lewati", style: TextStyle(color: Colors.grey)),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: controller.onNext,
                        child: Text(isLastPage ? "Mulai" : "Lanjutkan"),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, int currentPage) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: 8.0,
      decoration: BoxDecoration(
        color: currentPage == index ? Get.theme.primaryColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingItemModel item;
  const _OnboardingPage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0, left: 40.0, right: 40.0, bottom: 20.0), // [PERBAIKAN] Padding atas lebih besar, bawah lebih kecil
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gambar / Lottie
          Expanded( // [PERBAIKAN] Beri flex yang lebih kecil untuk gambar/Lottie
            flex: 3, // Sesuaikan nilai flex ini (misal 3, 4, 5)
            child: item.isLottie
                ? Lottie.asset(item.imagePath, repeat: true, fit: BoxFit.contain)
                : SvgPicture.asset(item.imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 20), // [PERBAIKAN] Kurangi jarak
          // Judul
          Expanded( // [BARU] Beri Expanded juga untuk teks
            flex: 2, // Sesuaikan nilai flex ini
            child: Column(
              children: [
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                const SizedBox(height: 10), // [PERBAIKAN] Kurangi jarak
                // Deskripsi
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}