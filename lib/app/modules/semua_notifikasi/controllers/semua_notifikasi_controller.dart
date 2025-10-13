import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';

class SemuaNotifikasiController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController authC = Get.find<AuthController>();
  final ConfigController configC = Get.find<ConfigController>();

  // Helper untuk mendapatkan referensi koleksi notifikasi
  CollectionReference<Map<String, dynamic>> get _notifCollectionRef => _firestore
      .collection('Sekolah').doc(configC.idSekolah)
      .collection('siswa').doc(authC.auth.currentUser!.uid)
      .collection('notifikasi');

  // Stream untuk mengambil SEMUA notifikasi, diurutkan dari yang terbaru
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllNotifications() {
    return _notifCollectionRef.orderBy('tanggal', descending: true).snapshots();
  }

  // Fungsi untuk menghapus satu notifikasi berdasarkan ID-nya
  Future<void> hapusNotifikasi(String notifId) async {
    try {
      await _notifCollectionRef.doc(notifId).delete();
      Get.snackbar("Berhasil", "Notifikasi telah dihapus.",
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Gagal menghapus notifikasi: $e");
    }
  }

  // Fungsi untuk menghapus SEMUA notifikasi menggunakan Batch Delete
  Future<void> hapusSemuaNotifikasi() async {
    // Tampilkan dialog konfirmasi terlebih dahulu
    Get.defaultDialog(
      title: "Konfirmasi",
      middleText: "Apakah Anda yakin ingin menghapus semua notifikasi? Tindakan ini tidak dapat dibatalkan.",
      textConfirm: "Ya, Hapus Semua",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back(); // Tutup dialog konfirmasi
        
        // Tampilkan dialog loading
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false
        );

        try {
          final snapshot = await _notifCollectionRef.get();
          if (snapshot.docs.isEmpty) {
            Get.back(); // Tutup loading
            Get.snackbar("Info", "Tidak ada notifikasi untuk dihapus.");
            return;
          }

          final WriteBatch batch = _firestore.batch();
          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();

          Get.back(); // Tutup loading
          Get.snackbar("Berhasil", "Semua notifikasi telah dihapus.",
              snackPosition: SnackPosition.BOTTOM);
        } catch (e) {
          Get.back(); // Tutup loading
          Get.snackbar("Error", "Gagal menghapus semua notifikasi: $e");
        }
      },
    );
  }
}