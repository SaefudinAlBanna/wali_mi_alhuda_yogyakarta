// lib/app/controllers/config_controller.dart (VERSI ORANG TUA - FINAL UNTUK DEPENDENCY)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart'; // Pastikan ini diimpor jika menggunakan Get.snackbar

import '../routes/app_pages.dart';
import 'account_manager_controller.dart'; 
import '../models/student_profile_preview_model.dart'; 

class ConfigController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _box = GetStorage();
  
  // [PERBAIKAN KRUSIAL]: Deklarasikan _accountManager sebagai 'late final'
  // tetapi inisialisasinya akan di onReady().
  late final AccountManagerController _accountManager; 

  late final String idSekolah;
  final RxMap<String, dynamic> infoUser = <String, dynamic>{}.obs;

  final RxString tahunAjaranAktif = "".obs;
  final RxString semesterAktif = "".obs;
  final RxBool isKonfigurasiLoading = true.obs;

  final RxMap<String, dynamic> konfigurasiDashboard = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    idSekolah = dotenv.env['ID_SEKOLAH']!;
    // [PERBAIKAN KRUSIAL]: HAPUS BARIS INI DARI onInit()
    // _accountManager = Get.find<AccountManagerController>(); // BARIS INI HARUS DIHAPUS DARI SINI
  }

  @override
  void onReady() {
    super.onReady();
    // [PERBAIKAN KRUSIAL]: Inisialisasi _accountManager di onReady()
    // Ini memastikan AccountManagerController sudah di-put di main.dart
    // dan sudah melewati onInit()-nya sendiri.
    _accountManager = Get.find<AccountManagerController>(); 
    print("✅ [ConfigController] _accountManager initialized in onReady.");
  }

  Future<void> initAuthenticatedData() async {
    isKonfigurasiLoading.value = true;
    await Future.wait([
      _fetchKonfigurasiAkademik(),
      _syncKonfigurasiDashboard(),
    ]);
    isKonfigurasiLoading.value = false;
  }

  Future<void> _syncKonfigurasiDashboard() async {
    try {
      final doc = await _firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('pengaturan').doc('konfigurasi_dashboard')
          .get();
      if (doc.exists && doc.data() != null) {
        konfigurasiDashboard.value = doc.data()!;
      }
    } catch (e) {
      print("### Gagal mengambil konfigurasi dashboard: $e");
    }
  }

  Future<void> _fetchKonfigurasiAkademik() async {
    try {
      final snapshot = await _firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran')
          .where('isAktif', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        tahunAjaranAktif.value = doc.id;
        semesterAktif.value = doc.data()['semesterAktif']?.toString() ?? '1';
      } else {
        tahunAjaranAktif.value = "TIDAK_AKTIF";
        semesterAktif.value = "0";
      }
    } catch (e) {
      tahunAjaranAktif.value = "ERROR";
      semesterAktif.value = "0";
      print("### Gagal memuat konfigurasi akademik: $e");
    } finally {
      // isKonfigurasiLoading.value = false; 
    }
  }

  Future<String> decideInitialRoute() async {
    final user = _auth.currentUser;
    if (user == null) {
      return Routes.LOGIN;
    }

    try {
      final userDoc = await _firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(user.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        await initAuthenticatedData(); 

        final profile = userDoc.data()!;
        final Map<String, dynamic> sanitizedProfile = Map<String, dynamic>.from(profile);
        sanitizedProfile.forEach((key, value) {
          if (value is Timestamp) {
            sanitizedProfile[key] = value.toDate().toIso8601String();
          }
        });
        
        infoUser.value = sanitizedProfile;
        await _box.write('userProfile', sanitizedProfile);

        final StudentProfilePreview updatedPreview = StudentProfilePreview(
          uid: user.uid,
          email: user.email!, 
          passwordEncrypted: _accountManager.getAccountByUid(user.uid)?.passwordEncrypted ?? '', 
          namaLengkap: profile['namaLengkap'] ?? 'Siswa',
          kelasId: profile['kelasId'] ?? 'N/A',
          fotoProfilUrl: profile['fotoProfilUrl'],
          peranKomite: profile['peranKomite'] as Map<String, dynamic>?, // <-- TAMBAHKAN BARIS INI
        );
        await _accountManager.addOrUpdateStudentAccount(updatedPreview); 

        if (profile['mustChangePassword'] == true) {
          return Routes.NEW_PASSWORD;
        } else if (profile['isProfileComplete'] == false) {
          return Routes.LENGKAPI_PROFIL;
        } else {
          return Routes.HOME;
        }
      } else {
        throw Exception("Profil siswa tidak ditemukan.");
      }
    } catch (e) {
      print("[ConfigController] Error deciding initial route: $e");
      await _box.remove('userProfile');
      await _auth.signOut();
      _accountManager.clearActiveStudent(); 
      Get.snackbar("Error Sesi", "Sesi tidak valid. Silakan login kembali.", backgroundColor: Colors.red, colorText: Colors.white);
      return Routes.LOGIN;
    }
  }
  
  Future<void> clearCache() async {
    await _box.remove('userProfile');
    infoUser.clear();
    tahunAjaranAktif.value = "";
    semesterAktif.value = "";
    konfigurasiDashboard.clear();
    isKonfigurasiLoading.value = true;
  }
}