import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/daftar_pembayaran_komite_controller.dart';

class DaftarPembayaranKomiteView
    extends GetView<DaftarPembayaranKomiteController> {
  const DaftarPembayaranKomiteView({super.key});

  //  final dataArgumen = Get.arguments;
   
  @override
  Widget build(BuildContext context) {
    // print("dataArgumen = ${dataArgumen[0]['namakelas']}");
    return Scaffold(
      appBar: AppBar(
        title: const Text('DaftarPembayaranKomiteView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'DaftarPembayaranKomiteView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
