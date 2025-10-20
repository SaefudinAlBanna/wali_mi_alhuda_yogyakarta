import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';

class JadwalSiswaController extends GetxController with GetTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();

  late TabController tabController;

  final isLoadingJadwal = true.obs;
  final RxMap<String, List<Map<String, dynamic>>> jadwalPelajaran = <String, List<Map<String, dynamic>>>{}.obs;
  final List<String> daftarHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: daftarHari.length, vsync: this);
    _fetchJadwal();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> _fetchJadwal() async {
    isLoadingJadwal.value = true;
    
    // Ambil data penting dari ConfigController
    final String kelasId = configC.infoUser['kelasId'] ?? '';
    final String tahunAjaran = configC.tahunAjaranAktif.value;

    if (kelasId.isEmpty || tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) {
      isLoadingJadwal.value = false;
      return;
    }

    try {
      final docSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('jadwalkelas').doc(kelasId)
          .get();

      if (docSnap.exists && docSnap.data() != null) {
        final dataJadwal = docSnap.data()!;
        for (var hari in daftarHari) {
          var pelajaranHari = List<Map<String, dynamic>>.from(dataJadwal[hari] ?? []);
          pelajaranHari.sort((a, b) => (a['jam'] as String).compareTo(b['jam'] as String));
          jadwalPelajaran[hari] = pelajaranHari;
        }
      } else {
        for (var hari in daftarHari) {
          jadwalPelajaran[hari] = [];
        }
      }
    } catch (e) {
      print(e);
      Get.snackbar('Error', 'Gagal memuat jadwal: ${e.toString()}');
    } finally {
      isLoadingJadwal.value = false;
    }
  }
}