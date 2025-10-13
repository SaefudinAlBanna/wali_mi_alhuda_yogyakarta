// lib/app/services/notifikasi_komite_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/account_manager_controller.dart';
import '../controllers/config_controller.dart';

class NotifikasiKomiteService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final ConfigController _configC = Get.find<ConfigController>();

  static Future<void> kirimNotifikasi({
    required String uidPenerima,
    required String judul,
    required String isi,
    String tipe = 'komite',
  }) async {
    // Validasi: Jangan kirim notifikasi ke diri sendiri
    if (uidPenerima == Get.find<AccountManagerController>().currentActiveStudent.value?.uid) {
      print("Info: Notifikasi ke diri sendiri dibatalkan.");
      return;
    }
    
    try {
      final siswaDocRef = _firestore
          .collection('Sekolah').doc(_configC.idSekolah)
          .collection('siswa').doc(uidPenerima);

      final notifRef = siswaDocRef.collection('notifikasi').doc();
      final metaRef = siswaDocRef.collection('notifikasi_meta').doc('metadata');

      final batch = _firestore.batch();

      batch.set(notifRef, {
        'judul': judul,
        'isi': isi,
        'tipe': tipe,
        'isDibaca': false,
        'tanggal': FieldValue.serverTimestamp(),
      });

      batch.set(metaRef, {'unreadCount': FieldValue.increment(1)}, SetOptions(merge: true));

      await batch.commit();
      print("✅ Notifikasi Komite terkirim ke $uidPenerima: $judul");

    } catch (e) {
      print("❌ Gagal mengirim Notifikasi Komite ke $uidPenerima: $e");
    }
  }
}