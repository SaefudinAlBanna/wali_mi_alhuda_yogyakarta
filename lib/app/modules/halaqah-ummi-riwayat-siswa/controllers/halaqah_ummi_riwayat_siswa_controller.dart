import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/account_manager_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/halaqah_setoran_ummi_model.dart'; // Pastikan path model ini benar

class HalaqahUmmiRiwayatSiswaController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AccountManagerController accountManagerC = Get.find<AccountManagerController>();
  final ConfigController configC = Get.find<ConfigController>();

  // Gunakan RxString agar bisa reaktif terhadap perubahan akun siswa
  final RxString activeStudentUid = "".obs;

  @override
  void onInit() {
    super.onInit();
    // Set UID awal
    activeStudentUid.value = accountManagerC.currentActiveStudent.value?.uid ?? "";

    // Dengarkan jika ada pergantian akun siswa
    ever(accountManagerC.currentActiveStudent, (student) {
      activeStudentUid.value = student?.uid ?? "";
    });
  }

  // Stream untuk progres terkini siswa
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamProgresSiswa() {
    if (activeStudentUid.value.isEmpty) return const Stream.empty();
    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').doc(activeStudentUid.value)
        .snapshots();
  }

  // Stream untuk riwayat setoran
  Stream<QuerySnapshot<Map<String, dynamic>>> streamRiwayatSetoran() {
    if (activeStudentUid.value.isEmpty) return const Stream.empty();
    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').doc(activeStudentUid.value)
        .collection('halaqah_setoran_ummi')
        .orderBy('tanggalSetor', descending: true)
        .snapshots();
  }

  // Fungsi untuk membuka dialog tambah/edit catatan orang tua
  void openCatatanOrangTuaDialog(HalaqahSetoranUmmiModel setoran) {
    final catatanC = TextEditingController(text: setoran.catatanOrangTua);
    Get.defaultDialog(
      title: "Tanggapan Orang Tua",
      content: TextField(
        controller: catatanC,
        maxLines: 4,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: "Tulis tanggapan atau pertanyaan...",
        ),
      ),
      textCancel: "Batal",
      textConfirm: "Kirim",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back(); // Tutup dialog
        try {
          await _firestore
              .collection('Sekolah').doc(configC.idSekolah)
              .collection('siswa').doc(activeStudentUid.value)
              .collection('halaqah_setoran_ummi').doc(setoran.id)
              .update({'catatanOrangTua': catatanC.text.trim()});
          Get.snackbar("Berhasil", "Tanggapan Anda telah terkirim.");
        } catch (e) {
          Get.snackbar("Error", "Gagal mengirim tanggapan: $e");
        }
      },
    );
  }
}