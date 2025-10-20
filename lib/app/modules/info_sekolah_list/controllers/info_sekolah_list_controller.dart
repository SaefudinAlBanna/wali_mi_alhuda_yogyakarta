// [READ-ONLY VERSION UNTUK ORANG TUA]
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../controllers/config_controller.dart';

class InfoSekolahListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  late final CollectionReference<Map<String, dynamic>> _infoRef;
  late Stream<QuerySnapshot<Map<String, dynamic>>> streamInfo;

  @override
  void onInit() {
    super.onInit();
    final String tahunAjaran = configC.tahunAjaranAktif.value;
    _infoRef = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('info_sekolah');
    
    streamInfo = _infoRef.orderBy('timestamp', descending: true).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getInfoById(String docId) {
    return _infoRef.doc(docId).get();
  }

  Future<void> shareInfo(Map<String, dynamic> infoData) async {
    final String judul = infoData['judul'] ?? 'Tanpa Judul';
    final String isi = infoData['isi'] ?? 'Tidak ada konten.';
    final String imageUrl = infoData['imageUrl'] ?? '';
    final String teksUntukShare = "Info Sekolah: *$judul*\n\n$isi";

    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      if (imageUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(imageUrl));
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/info_sekolah_image.jpg';
        await File(path).writeAsBytes(bytes);
        Get.back();
        await Share.shareXFiles([XFile(path)], text: teksUntukShare);
      } else {
        Get.back();
        await Share.share(teksUntukShare);
      }
    } catch (e) {
      Get.back();
      Get.snackbar("Gagal Berbagi", "Terjadi kesalahan: $e");
    }
  }
}