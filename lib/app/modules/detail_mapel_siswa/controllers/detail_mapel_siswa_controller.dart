// lib/app/modules/detail_mapel_siswa/controllers/detail_mapel_siswa_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/nilai_harian_model.dart';
import '../../../models/pengumuman_mapel_model.dart';

class DetailMapelSiswaController extends GetxController with GetTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController authC = Get.find<AuthController>();
  final ConfigController configC = Get.find<ConfigController>();

  late String idMapel, namaMapel, namaGuru, tahunAjaran, semester, kelasId;
  late TabController tabController;
  
  late Future<Map<String, dynamic>> dataMapel;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    idMapel = args['idMapel'] ?? '';
    namaMapel = args['namaMapel'] ?? 'Detail Mapel';
    namaGuru = args['namaGuru'] ?? '';
    tahunAjaran = args['tahunAjaran'] ?? '';
    semester = args['semester'] ?? '';
    kelasId = args['kelasId'] ?? '';

    // [PERBAIKAN] Panggil fetchAllData() hanya setelah configC.isKonfigurasiLoading false
    // agar tahunAjaran, semester, kelasId, dll. sudah dijamin terisi.
    // Jika tidak menggunakan FutureBuilder, Anda bisa menggunakan ever listener.
    // Karena Anda menggunakan FutureBuilder, inisialisasi dataMapel di sini sudah cukup.
    // Namun, pastikan argumen yang diterima goToDetailMapel sudah lengkap.
    dataMapel = fetchAllData();
  }

  Future<Map<String, dynamic>> fetchAllData() async {
    final uid = authC.auth.currentUser!.uid;

    // --- [PERBAIKAN KUNCI] Koreksi Path `siswaMapelRef` ---
    final siswaMapelRef = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('kelastahunajaran').doc(kelasId)
        .collection('daftarsiswa').doc(uid)      // <--- DAFTAR SISWA SEBELUM SEMESTER
        .collection('semester').doc(semester)
        .collection('matapelajaran').doc(idMapel);
    // --- AKHIR PERBAIKAN PATH ---

    final pengumumanRef = _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('kelastahunajaran').doc(kelasId)
        .collection('semester').doc(semester)
        .collection('tugas_ulangan')
        .where('idMapel', isEqualTo: idMapel)
        .orderBy('tanggal_dibuat', descending: true);

    final results = await Future.wait([
      pengumumanRef.get(),
      siswaMapelRef.get(),
      siswaMapelRef.collection('nilai_harian').get(),
    ]);

    final pengumumanDocs = (results[0] as QuerySnapshot).docs;
    final nilaiUtamaDoc = (results[1] as DocumentSnapshot);
    final nilaiHarianDocs = (results[2] as QuerySnapshot).docs;

    return {
      'pengumuman': pengumumanDocs.map((doc) => PengumumanMapelModel.fromFirestore(doc as QueryDocumentSnapshot<Map<String, dynamic>>)).toList(),
      'nilaiUtama': nilaiUtamaDoc.data() as Map<String, dynamic>? ?? {},
      'nilaiHarian': nilaiHarianDocs.map((doc) => NilaiHarianModel.fromFirestore(doc as QueryDocumentSnapshot<Map<String, dynamic>>)).toList(),
    };
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}