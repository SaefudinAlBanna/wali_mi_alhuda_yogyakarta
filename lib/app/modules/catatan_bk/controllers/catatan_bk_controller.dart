import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/account_manager_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/catatan_bk_model.dart';
import '../../../routes/app_pages.dart';

class CatatanBkController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final AccountManagerController accountManagerC = Get.find<AccountManagerController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Referensi Dokumen ---
  DocumentReference? get siswaDocRef {
    final uid = accountManagerC.currentActiveStudent.value?.uid;
    if (uid == null) return null;
    return _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(uid);
  }

  // --- State untuk List View ---
  final RxBool isListLoading = true.obs;
  final RxList<CatatanBkModel> daftarCatatan = <CatatanBkModel>[].obs;

  // --- State untuk Detail View ---
  final RxBool isDetailLoading = true.obs;
  final Rxn<CatatanBkModel> catatanDetail = Rxn<CatatanBkModel>();
  final RxList<DocumentSnapshot> komentarList = <DocumentSnapshot>[].obs;
  StreamSubscription? _komentarSubscription;

  // --- Controller Form ---
  final TextEditingController komentarController = TextEditingController();
  final RxBool isSendingKomentar = false.obs;

  @override
  void onClose() {
    _komentarSubscription?.cancel();
    komentarController.dispose();
    super.onClose();
  }

  // --- Logika untuk List View ---
  Future<void> fetchCatatanList() async {
    isListLoading.value = true;
    if (siswaDocRef == null) {
      isListLoading.value = false;
      Get.snackbar('Error', 'Tidak ada akun siswa yang aktif.');
      return;
    }
    try {
      final snapshot = await siswaDocRef!
          .collection('catatan_bk')
          .orderBy('tanggalDibuat', descending: true)
          .get();
      
      daftarCatatan.value = snapshot.docs.map((doc) => CatatanBkModel.fromFirestore(doc)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data: ${e.toString()}');
    } finally {
      isListLoading.value = false;
    }
  }

  // --- Logika untuk Detail View ---
  Future<void> fetchDetailAndKomentar(String catatanId) async {
    isDetailLoading.value = true;
    _komentarSubscription?.cancel();
     if (siswaDocRef == null) {
      isDetailLoading.value = false;
      return;
    }
    try {
      final doc = await siswaDocRef!.collection('catatan_bk').doc(catatanId).get();
      if (doc.exists) {
        catatanDetail.value = CatatanBkModel.fromFirestore(doc);
        _listenToKomentar(catatanId);
      } else {
         Get.snackbar('Error', 'Catatan tidak ditemukan.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat detail catatan: ${e.toString()}');
    } finally {
      isDetailLoading.value = false;
    }
  }

  void _listenToKomentar(String catatanId) {
    _komentarSubscription = siswaDocRef!
        .collection('catatan_bk').doc(catatanId)
        .collection('komentar')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      komentarList.value = snapshot.docs;
    });
  }

  Future<void> addKomentar(String catatanId) async {
    if (komentarController.text.trim().isEmpty || siswaDocRef == null) return;
    isSendingKomentar.value = true;
    try {
      final student = accountManagerC.currentActiveStudent.value!;
      final peranKomite = student.peranKomite;
      
      // Gunakan nama tampilan orang tua jika ada, jika tidak gunakan nama siswa
      final namaPenulis = peranKomite?['namaOrangTua'] ?? student.namaLengkap;

      await siswaDocRef!.collection('catatan_bk').doc(catatanId).collection('komentar').add({
        'isi': komentarController.text.trim(),
        'penulisId': student.uid,
        'penulisNama': namaPenulis,
        'penulisPeran': 'Orang Tua', // Peran sudah pasti
        'timestamp': FieldValue.serverTimestamp(),
      });
      komentarController.clear();
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengirim komentar: ${e.toString()}');
    } finally {
      isSendingKomentar.value = false;
    }
  }

  // --- Navigasi ---
  void goToDetail(CatatanBkModel catatan) {
    Get.toNamed(Routes.CATATAN_BK_DETAIL, arguments: {'catatanId': catatan.id});
  }
}