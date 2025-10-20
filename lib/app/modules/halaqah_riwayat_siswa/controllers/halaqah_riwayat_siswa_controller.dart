// lib/app/modules/halaqah_riwayat_siswa/controllers/halaqah_riwayat_siswa_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/halaqah_setoran_model.dart';

class HalaqahRiwayatSiswaController extends GetxController with GetTickerProviderStateMixin { // [PERBAIKAN] Tambahkan GetTickerProviderStateMixin
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();

  final isSending = false.obs;

  final RxString selectedTahunAjaran = "".obs;
  final RxString selectedSemester = "".obs;
  final RxList<String> daftarTahunAjaran = <String>[].obs;
  final RxList<String> daftarSemester = <String>['1', '2'].obs;

  late TabController tabController; // [BARU] TabController
  final RxBool hasHalaqahGroup = false.obs; // [BARU] Untuk cek apakah siswa punya grup halaqah

  @override
  void onInit() {
    super.onInit();
    // Inisialisasi awal dengan tahun ajaran & semester aktif dari configC
    selectedTahunAjaran.value = configC.tahunAjaranAktif.value;
    selectedSemester.value = configC.semesterAktif.value;

    tabController = TabController(length: daftarSemester.length, vsync: this);
    _setInitialTab(); // Atur tab awal berdasarkan semester aktif

    // Listen untuk perubahan semester yang dipilih di tab
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        selectedSemester.value = daftarSemester[tabController.index];
        checkIfSiswaHasHalaqahGroup(); // Cek ulang grup saat semester berubah
        update(); // Memicu GetBuilder untuk me-refresh stream
      }
    });

    _fetchDaftarTahunAjaranHalaqah();
    checkIfSiswaHasHalaqahGroup(); // Cek status grup di awal
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void _setInitialTab() {
    final int currentSemesterIndex = daftarSemester.indexOf(configC.semesterAktif.value);
    if (currentSemesterIndex != -1) {
      tabController.index = currentSemesterIndex;
    }
  }

  Future<void> _fetchDaftarTahunAjaranHalaqah() async {
    final uid = authC.auth.currentUser!.uid;
    if (uid.isEmpty) {
      daftarTahunAjaran.clear();
      update();
      return;
    }

    try {
      final querySnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').doc(uid)
          .collection('halaqah_nilai')
          .orderBy('tahunAjaran', descending: true)
          .get();

      final Set<String> uniqueTahunAjaran = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('tahunAjaran') && data['tahunAjaran'] != null) {
          uniqueTahunAjaran.add(data['tahunAjaran'] as String);
        }
      }
      daftarTahunAjaran.assignAll(uniqueTahunAjaran.toList()..sort((a,b) => b.compareTo(a)));
      
      if (daftarTahunAjaran.isNotEmpty && !daftarTahunAjaran.contains(selectedTahunAjaran.value)) {
        selectedTahunAjaran.value = daftarTahunAjaran.first;
      } else if (daftarTahunAjaran.isEmpty) {
        selectedTahunAjaran.value = ""; // Bersihkan jika tidak ada
      }
      
      checkIfSiswaHasHalaqahGroup(); // Cek ulang grup setelah TA dimuat
      update();
    } catch (e) {
      print("[HalaqahRiwayatSiswaController] Error fetching halaqah years: $e");
      daftarTahunAjaran.clear();
      update();
    }
  }

  // [BARU] Fungsi untuk memeriksa apakah siswa memiliki grup halaqah untuk TA & Semester terpilih
  Future<void> checkIfSiswaHasHalaqahGroup() async {
    final uid = authC.auth.currentUser!.uid;
    final ta = selectedTahunAjaran.value;
    final sem = selectedSemester.value;

    if (uid.isEmpty || ta.isEmpty || sem.isEmpty) {
      hasHalaqahGroup.value = false;
      return;
    }

    try {
      final siswaDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').doc(uid).get();
      
      final data = siswaDoc.data();
      if (data != null && data.containsKey('grupHalaqah')) {
        final Map<String, dynamic> grupHalaqahMap = data['grupHalaqah'];
        final key = "$ta\_$sem";
        hasHalaqahGroup.value = grupHalaqahMap.containsKey(key) && grupHalaqahMap[key] != null;
      } else {
        hasHalaqahGroup.value = false;
      }
    } catch (e) {
      print("[HalaqahRiwayatSiswaController] Error checking halaqah group: $e");
      hasHalaqahGroup.value = false;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamRiwayat() {
    final uid = authC.auth.currentUser!.uid;
    if (uid.isEmpty || selectedTahunAjaran.value.isEmpty || selectedSemester.value.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').doc(uid)
        .collection('halaqah_nilai')
        .where('tahunAjaran', isEqualTo: selectedTahunAjaran.value)
        .where('semester', isEqualTo: selectedSemester.value)
        .orderBy('tanggalTugas', descending: true)
        .snapshots();
  }

  Future<void> kirimCatatan(String setoranId, TextEditingController controller) async {
    final catatan = controller.text.trim();
    if (catatan.isEmpty) {
      Get.snackbar("Peringatan", "Catatan tidak boleh kosong.");
      return;
    }
    
    isSending.value = true;
    try {
      final uid = authC.auth.currentUser!.uid;
      final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').doc(uid)
        .collection('halaqah_nilai').doc(setoranId);

      await docRef.update({'catatanOrangTua': catatan});
      
      Get.snackbar("Berhasil", "Catatan Anda telah terkirim.", backgroundColor: Colors.green, colorText: Colors.white);
      controller.clear();
      Get.focusScope?.unfocus();

    } catch (e) {
      Get.snackbar("Error", "Gagal mengirim catatan: $e");
      print("[HalaqahRiwayatSiswaController] Error sending note: $e");
    } finally {
      isSending.value = false;
    }
  }

  Future<void> daftarAntrianSetoran(HalaqahSetoranModel setoran) async {
    isSending.value = true;
    try {
      final uid = authC.auth.currentUser!.uid;
      final namaSiswa = configC.infoUser['namaLengkap'] ?? 'Nama Siswa';
      final waktuSekarang = FieldValue.serverTimestamp();

      final grupId = setoran.idGrup; 
      final tahunAjaran = setoran.tahunAjaran;

      if (grupId == null || grupId.isEmpty || tahunAjaran.isEmpty) {
        throw Exception("ID Grup atau Tahun Ajaran tidak valid untuk antrian.");
      }

      final grupRef = _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('halaqah_grup').doc(grupId);

      final setoranRef = _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').doc(uid)
          .collection('halaqah_nilai').doc(setoran.id);

      final WriteBatch batch = _firestore.batch();
      
      batch.update(setoranRef, {'waktuAntri': waktuSekarang});

      batch.set(grupRef, {
        'antrianSetoran': {
          uid: {
            'nama': namaSiswa,
            'waktu': waktuSekarang
          }
        }
      }, SetOptions(merge: true));

      await batch.commit();
      Get.snackbar("Berhasil", "Anda telah terdaftar dalam antrian setoran.", backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) { 
      Get.snackbar("Error", "Gagal mendaftar antrian: ${e.toString()}"); 
      print("[HalaqahRiwayatSiswaController] Error registering queue: $e");
    } 
    finally { isSending.value = false; }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamAntrianGrup(HalaqahSetoranModel setoran) {
    if (setoran.idGrup == null || setoran.idGrup.isEmpty || setoran.tahunAjaran.isEmpty) {
      return const Stream.empty();
    }
    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(setoran.tahunAjaran)
        .collection('halaqah_grup').doc(setoran.idGrup)
        .snapshots();
  }
}


// // lib/app/modules/halaqah_riwayat_siswa/controllers/halaqah_riwayat_siswa_controller.dart

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import '../../../controllers/auth_controller.dart';
// import '../../../controllers/config_controller.dart';
// import '../../../models/halaqah_setoran_model.dart';

// class HalaqahRiwayatSiswaController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ConfigController configC = Get.find<ConfigController>();
//   final AuthController authC = Get.find<AuthController>();

//   final isSending = false.obs;

//   // [BARU] State untuk filter Tahun Ajaran dan Semester
//   final RxString selectedTahunAjaran = "".obs;
//   final RxString selectedSemester = "".obs;
//   final RxList<String> daftarTahunAjaran = <String>[].obs;
//   final RxList<String> daftarSemester = <String>['1', '2'].obs; // Asumsi hanya 1 dan 2

//   @override
//   void onInit() {
//     super.onInit();
//     // Inisialisasi awal dengan tahun ajaran & semester aktif
//     selectedTahunAjaran.value = configC.tahunAjaranAktif.value;
//     selectedSemester.value = configC.semesterAktif.value;

//     // Ambil daftar tahun ajaran yang pernah ada setoran halaqah
//     _fetchDaftarTahunAjaranHalaqah();
//   }

//   Future<void> _fetchDaftarTahunAjaranHalaqah() async {
//     final uid = authC.auth.currentUser!.uid;
//     if (uid.isEmpty) return;

//     try {
//       // Query grup halaqah siswa, lalu ekstrak tahun ajaran unik
//       final querySnapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
//           .collection('siswa').doc(uid)
//           .collection('halaqah_nilai')
//           .orderBy('tahunAjaran', descending: true)
//           .get();

//       final Set<String> uniqueTahunAjaran = {};
//       for (var doc in querySnapshot.docs) {
//         final data = doc.data();
//         if (data.containsKey('tahunAjaran') && data['tahunAjaran'] != null) {
//           uniqueTahunAjaran.add(data['tahunAjaran'] as String);
//         }
//       }
//       daftarTahunAjaran.assignAll(uniqueTahunAjaran.toList()..sort((a,b) => b.compareTo(a))); // Urutkan terbaru di atas
      
//       // Jika ada tahun ajaran yang lebih baru dari yang aktif, default ke yang terbaru
//       if (daftarTahunAjaran.isNotEmpty && daftarTahunAjaran.first != configC.tahunAjaranAktif.value) {
//         selectedTahunAjaran.value = daftarTahunAjaran.first;
//       }
      
//       // Pemicu untuk me-refresh stream riwayat
//       update(); // Panggil update agar StreamBuilder di UI bereaksi
//     } catch (e) {
//       print("[HalaqahRiwayatSiswaController] Error fetching halaqah years: $e");
//     }
//   }

//   Stream<QuerySnapshot<Map<String, dynamic>>> streamRiwayat() {
//     final uid = authC.auth.currentUser!.uid;
//     // [PERBAIKAN] Filter berdasarkan selectedTahunAjaran dan selectedSemester
//     if (uid == null || selectedTahunAjaran.value.isEmpty || selectedSemester.value.isEmpty) {
//       return const Stream.empty();
//     }

//     return _firestore
//         .collection('Sekolah').doc(configC.idSekolah)
//         .collection('siswa').doc(uid)
//         .collection('halaqah_nilai')
//         .where('tahunAjaran', isEqualTo: selectedTahunAjaran.value) // Filter TA
//         .where('semester', isEqualTo: selectedSemester.value)     // Filter Semester
//         .orderBy('tanggalTugas', descending: true)
//         .snapshots();
//   }

//   Future<void> kirimCatatan(String setoranId, TextEditingController controller) async {
//     final catatan = controller.text.trim();
//     if (catatan.isEmpty) {
//       Get.snackbar("Peringatan", "Catatan tidak boleh kosong.");
//       return;
//     }
    
//     isSending.value = true;
//     try {
//       final uid = authC.auth.currentUser!.uid;
//       final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
//         .collection('siswa').doc(uid)
//         .collection('halaqah_nilai').doc(setoranId);

//       await docRef.update({'catatanOrangTua': catatan});
      
//       Get.snackbar("Berhasil", "Catatan Anda telah terkirim.", backgroundColor: Colors.green, colorText: Colors.white);
//       controller.clear();
//       Get.focusScope?.unfocus();

//     } catch (e) {
//       Get.snackbar("Error", "Gagal mengirim catatan: $e");
//       print("[HalaqahRiwayatSiswaController] Error sending note: $e");
//     } finally {
//       isSending.value = false;
//     }
//   }

//   Future<void> daftarAntrianSetoran(HalaqahSetoranModel setoran) async {
//     isSending.value = true;
//     try {
//       final uid = authC.auth.currentUser!.uid;
//       final namaSiswa = configC.infoUser['namaLengkap'] ?? 'Nama Siswa';
//       final waktuSekarang = FieldValue.serverTimestamp();

//       final grupId = setoran.idGrup; 
//       final tahunAjaran = setoran.tahunAjaran;

//       if (grupId == null || grupId.isEmpty || tahunAjaran.isEmpty) {
//         throw Exception("ID Grup atau Tahun Ajaran tidak valid untuk antrian.");
//       }

//       final grupRef = _firestore
//           .collection('Sekolah').doc(configC.idSekolah)
//           .collection('tahunajaran').doc(tahunAjaran)
//           .collection('halaqah_grup').doc(grupId);

//       final setoranRef = _firestore
//           .collection('Sekolah').doc(configC.idSekolah)
//           .collection('siswa').doc(uid)
//           .collection('halaqah_nilai').doc(setoran.id);

//       final WriteBatch batch = _firestore.batch();
      
//       batch.update(setoranRef, {'waktuAntri': waktuSekarang});

//       batch.set(grupRef, {
//         'antrianSetoran': {
//           uid: {
//             'nama': namaSiswa,
//             'waktu': waktuSekarang
//           }
//         }
//       }, SetOptions(merge: true));

//       await batch.commit();
//       Get.snackbar("Berhasil", "Anda telah terdaftar dalam antrian setoran.", backgroundColor: Colors.green, colorText: Colors.white);

//     } catch (e) { 
//       Get.snackbar("Error", "Gagal mendaftar antrian: ${e.toString()}"); 
//       print("[HalaqahRiwayatSiswaController] Error registering queue: $e");
//     } 
//     finally { isSending.value = false; }
//   }

//   Stream<DocumentSnapshot<Map<String, dynamic>>> streamAntrianGrup(HalaqahSetoranModel setoran) {
//     if (setoran.idGrup == null || setoran.idGrup.isEmpty || setoran.tahunAjaran.isEmpty) {
//       return const Stream.empty();
//     }
//     return _firestore
//         .collection('Sekolah').doc(configC.idSekolah)
//         .collection('tahunajaran').doc(setoran.tahunAjaran)
//         .collection('halaqah_grup').doc(setoran.idGrup)
//         .snapshots();
//   }
// }