// lib/app/controllers/account_manager_controller.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/student_profile_preview_model.dart';
import '../services/auth_secure_storage_service.dart';
import '../routes/app_pages.dart';
import 'config_controller.dart'; 

class AccountManagerController extends GetxController {
  final AuthSecureStorageService _authStorage = Get.find<AuthSecureStorageService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // final ConfigController _configC = Get.find<ConfigController>(); 
  late final ConfigController _configC; 

  final Rxn<StudentProfilePreview> currentActiveStudent = Rxn<StudentProfilePreview>();
  final RxBool isProcessingAccount = false.obs;

  @override
  void onInit() {
    super.onInit();
    // [PERBAIKAN KRUSIAL]: Inisialisasi _configC di onInit()
    _configC = Get.find<ConfigController>(); 

    // Reaksi terhadap perubahan activeStudentUid di storage service
    ever(_authStorage.activeStudentUid, (uid) {
      if (uid != null) {
        currentActiveStudent.value = _authStorage.getAccountByUid(uid);
      } else {
        currentActiveStudent.value = null;
      }
      print("👤 [AccountManagerController] Current active student updated: ${currentActiveStudent.value?.namaLengkap}");
    });

    // Inisialisasi awal active student
    if (_authStorage.activeStudentUid.value != null) {
      currentActiveStudent.value = _authStorage.getAccountByUid(_authStorage.activeStudentUid.value!);
    } else if (_authStorage.studentAccounts.isNotEmpty) {
      // Jika tidak ada yang aktif, set yang pertama sebagai aktif
      _authStorage.saveActiveStudentUid(_authStorage.studentAccounts.first.uid);
    }
  }

  // Dipanggil setelah login Firebase Auth berhasil dari AuthController
  Future<void> addOrSwitchLoggedInStudent(String email, String passwordPlain) async {
    isProcessingAccount.value = true;
    try {
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception("Firebase user is null after login attempt.");
      }

      // Ambil detail profil siswa dari Firestore
      DocumentSnapshot studentDoc = await _firestore
          .collection('Sekolah').doc(_configC.idSekolah) 
          .collection('siswa').doc(firebaseUser.uid)
          .get();

      if (!studentDoc.exists || studentDoc.data() == null) {
        await _auth.signOut(); 
        throw Exception("Profil siswa tidak ditemukan di Firestore. Silakan hubungi admin.");
      }

      final studentData = studentDoc.data() as Map<String, dynamic>;

      // Buat StudentProfilePreview dengan password asli (akan dienkripsi oleh secure storage)
      final StudentProfilePreview studentPreview = StudentProfilePreview(
        uid: firebaseUser.uid,
        email: email,
        passwordEncrypted: passwordPlain, // SecureStorage akan mengenkripsi ini
        namaLengkap: studentData['namaLengkap'] ?? 'Siswa',
        kelasId: studentData['kelasId'] ?? 'N/A',
        fotoProfilUrl: studentData['fotoProfilUrl'],
      );

      await _authStorage.addOrUpdateAccount(studentPreview);
      await _authStorage.saveActiveStudentUid(studentPreview.uid); 

      print("✅ [AccountManagerController] Account ${studentPreview.namaLengkap} added/switched.");
    } catch (e) {
      Get.snackbar("Error Akun", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      print("❌ [AccountManagerController] Error adding/switching account: $e");
      await _auth.signOut(); 
    } finally {
      isProcessingAccount.value = false;
    }
  }

  // Untuk beralih akun dari UI Switcher
  Future<void> switchStudentAccount(String targetUid) async {
    if (currentActiveStudent.value?.uid == targetUid) {
      Get.snackbar("Informasi", "Akun ini sudah aktif.");
      return;
    }

    final targetAccount = _authStorage.getAccountByUid(targetUid);
    if (targetAccount == null) {
      Get.snackbar("Error", "Akun tidak ditemukan di daftar tersimpan.");
      return;
    }

    isProcessingAccount.value = true;
    try {
      await _auth.signOut(); 
      
      // Login ke akun target
      await _auth.signInWithEmailAndPassword(
        email: targetAccount.email,
        password: targetAccount.passwordEncrypted, // Password yang didekripsi
      );
      
      await _authStorage.saveActiveStudentUid(targetUid); 
      Get.snackbar("Berhasil", "Beralih ke akun ${targetAccount.namaLengkap}");
      
      Get.offAllNamed(Routes.SPLASH); 

    } on FirebaseAuthException catch (e) {
      String msg = "Gagal beralih akun. Kredensial mungkin sudah tidak berlaku. (${e.code})";
      print("❌ [AccountManagerController] Firebase Auth error during switch: ${e.code} - ${e.message}");
      Get.snackbar("Gagal Beralih", msg, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      await _authStorage.removeAccount(targetUid); 
      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      print("❌ [AccountManagerController] General error during switch: $e");
      Get.snackbar("Gagal Beralih", "Terjadi kesalahan: ${e.toString()}", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      Get.offAllNamed(Routes.LOGIN);
    } finally {
      isProcessingAccount.value = false;
    }
  }

  // Untuk menghapus akun dari daftar lokal
  Future<void> removeStudentAccount(String uid) async {
    Get.defaultDialog(
      title: "Hapus Akun",
      middleText: "Anda yakin ingin menghapus akun ${(_authStorage.getAccountByUid(uid))?.namaLengkap ?? 'ini'} dari daftar?",
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await _authStorage.removeAccount(uid);
            // Jika akun yang aktif dihapus, dan ada akun lain, switch ke akun lain
            if (currentActiveStudent.value?.uid == uid) { // Menggunakan currentActiveStudent
              if (_authStorage.studentAccounts.isNotEmpty) {
                 await switchStudentAccount(_authStorage.studentAccounts.first.uid);
              } else {
                 await _auth.signOut(); 
                 Get.offAllNamed(Routes.LOGIN); 
              }
            } else {
              Get.back();
              Get.snackbar("Berhasil", "Akun telah dihapus.");
            }
          },
          child: const Text("Hapus"),
        ),
      ],
    );
  }

  // Untuk logout total dari semua akun tersimpan (dari AuthManagerController)
  Future<void> logoutAllAccounts() async {
    isProcessingAccount.value = true;
    try {
      await _authStorage.clearAllAccounts(); 
      await _auth.signOut(); 
      Get.snackbar("Logout", "Anda telah keluar dari semua akun.");
      Get.offAllNamed(Routes.LOGIN); 
    } catch (e) {
      Get.snackbar("Error Logout", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isProcessingAccount.value = false;
    }
  }
  
  // [FIXED] METHOD BARU: Untuk menghapus hanya akun aktif (dipanggil setelah logout dari AuthController)
  Future<void> clearActiveStudent() async {
    print("🗑️ [AccountManagerController] clearActiveStudent called.");
    if (_authStorage.activeStudentUid.value != null) {
      // Hapus hanya activeStudentUid dari penyimpanan
      await _authStorage.removeAccount(_authStorage.activeStudentUid.value!); 
      
      // Jika masih ada akun lain, set yang pertama sebagai aktif
      if (_authStorage.studentAccounts.isNotEmpty) {
        await _authStorage.saveActiveStudentUid(_authStorage.studentAccounts.first.uid);
        print("🗑️ [AccountManagerController] Switched to next available account: ${_authStorage.activeStudentUid.value}");
        // Tidak perlu login Firebase Auth lagi di sini, karena alur AuthController.logout sudah menavigasi ke LOGIN
        // dan SplashController akan mencoba auto-login ke akun baru yang aktif.
      } else {
        await _authStorage.removeActiveStudentUid(); // Hapus active UID jika tidak ada akun lain
        print("🗑️ [AccountManagerController] No other accounts left.");
      }
    }
    currentActiveStudent.value = null; // Update state reaktif
  }

  // [FIXED] METHOD BARU: Getter untuk mendapatkan akun siswa berdasarkan UID
  StudentProfilePreview? getAccountByUid(String uid) {
    return _authStorage.getAccountByUid(uid);
  }

  // [FIXED] METHOD BARU: Method untuk update data profil siswa di storage lokal (dipanggil dari ConfigController)
  // Tanpa memicu login/logout Firebase Auth
  Future<void> addOrUpdateStudentAccount(StudentProfilePreview student) async {
    await _authStorage.addOrUpdateAccount(student);
    // Jika siswa yang diupdate adalah siswa aktif, update juga `currentActiveStudent`
    if (currentActiveStudent.value?.uid == student.uid) {
      currentActiveStudent.value = student;
    }
    print("🔄 [AccountManagerController] Student profile updated in local storage: ${student.namaLengkap}");
  }

  // Getter untuk mendapatkan daftar akun siswa yang tersimpan (dari AuthSecureStorageService)
  RxList<StudentProfilePreview> get storedStudentAccounts => _authStorage.studentAccounts;
}