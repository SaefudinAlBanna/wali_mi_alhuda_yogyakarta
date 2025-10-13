import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/input_dana_komite_controller.dart';

class InputDanaKomiteView extends GetView<InputDanaKomiteController> {
  const InputDanaKomiteView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InputDanaKomiteView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'InputDanaKomiteView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
