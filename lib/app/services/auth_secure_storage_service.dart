// lib/app/services/auth_secure_storage_service.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../models/student_profile_preview_model.dart';

class AuthSecureStorageService extends GetxService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _KEY_STUDENT_ACCOUNTS = 'student_accounts_list'; // untuk list of StudentProfilePreview
  static const String _KEY_ACTIVE_STUDENT_UID = 'active_student_uid'; // untuk UID siswa yang sedang aktif

  // Menggunakan RxList dan Rxn untuk reaktivitas
  final RxList<StudentProfilePreview> studentAccounts = <StudentProfilePreview>[].obs;
  final Rxn<String> activeStudentUid = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    print("🔒 [AuthSecureStorageService] onInit called. Loading stored accounts.");
    _loadAllAccounts(); // Muat semua akun saat service diinisialisasi
  }

  // Muat semua akun dan set akun aktif dari secure storage
  Future<void> _loadAllAccounts() async {
    try {
      // Muat daftar akun
      String? accountsJson = await _secureStorage.read(key: _KEY_STUDENT_ACCOUNTS);
      if (accountsJson != null && accountsJson.isNotEmpty) {
        List<dynamic> decodedList = json.decode(accountsJson);
        studentAccounts.assignAll(decodedList.map((e) => StudentProfilePreview.fromJson(e as Map<String, dynamic>)));
        print("🔒 [AuthSecureStorageService] Loaded ${studentAccounts.length} student accounts.");
      } else {
        print("🔒 [AuthSecureStorageService] No student accounts found in secure storage.");
      }

      // Muat UID akun aktif
      activeStudentUid.value = await _secureStorage.read(key: _KEY_ACTIVE_STUDENT_UID);
      print("🔒 [AuthSecureStorageService] Active student UID: ${activeStudentUid.value}");

      // Jika tidak ada akun aktif tapi ada akun tersimpan, jadikan yang pertama aktif
      if (activeStudentUid.value == null && studentAccounts.isNotEmpty) {
        await saveActiveStudentUid(studentAccounts.first.uid);
        print("🔒 [AuthSecureStorageService] Set first account as active: ${activeStudentUid.value}");
      }

    } catch (e) {
      print("❌ [AuthSecureStorageService] Error loading accounts: $e");
      // Handle error, mungkin dengan menghapus data yang korup atau memberitahu user
      await _secureStorage.delete(key: _KEY_STUDENT_ACCOUNTS);
      await _secureStorage.delete(key: _KEY_ACTIVE_STUDENT_UID);
      studentAccounts.clear();
      activeStudentUid.value = null;
    }
  }

  // Simpan daftar akun ke secure storage
  Future<void> _saveStudentAccounts() async {
    try {
      String jsonString = json.encode(studentAccounts.map((e) => e.toJson()).toList());
      await _secureStorage.write(key: _KEY_STUDENT_ACCOUNTS, value: jsonString);
      print("🔒 [AuthSecureStorageService] Student accounts saved.");
    } catch (e) {
      print("❌ [AuthSecureStorageService] Error saving accounts: $e");
    }
  }

  // Tambahkan atau update akun siswa di daftar lokal
  Future<void> addOrUpdateAccount(StudentProfilePreview account) async {
    final existingIndex = studentAccounts.indexWhere((s) => s.uid == account.uid);
    if (existingIndex != -1) {
      studentAccounts[existingIndex] = account; // Update jika UID sudah ada
      print("🔒 [AuthSecureStorageService] Updated existing student account: ${account.namaLengkap}");
    } else {
      studentAccounts.add(account); // Tambah baru
      print("🔒 [AuthSecureStorageService] Added new student account: ${account.namaLengkap}");
    }
    await _saveStudentAccounts();
  }

  Future<void> removeActiveStudentUid() async {
    activeStudentUid.value = null;
    await _secureStorage.delete(key: _KEY_ACTIVE_STUDENT_UID);
    print("🔒 [AuthSecureStorageService] Active student UID removed from storage.");
  }

  // Hapus akun berdasarkan UID
  Future<void> removeAccount(String uid) async {
    studentAccounts.removeWhere((s) => s.uid == uid);
    await _saveStudentAccounts();
    print("🔒 [AuthSecureStorageService] Removed student account: $uid");

    if (activeStudentUid.value == uid) {
      activeStudentUid.value = null; // Hapus active UID jika yang dihapus adalah yang aktif
      await _secureStorage.delete(key: _KEY_ACTIVE_STUDENT_UID);
      print("🔒 [AuthSecureStorageService] Active student UID cleared.");
    }
  }

  // Simpan UID akun yang sedang aktif
  Future<void> saveActiveStudentUid(String uid) async {
    activeStudentUid.value = uid;
    await _secureStorage.write(key: _KEY_ACTIVE_STUDENT_UID, value: uid);
    print("🔒 [AuthSecureStorageService] Active student UID set to: $uid");
  }

  // Hapus semua akun dari secure storage
  Future<void> clearAllAccounts() async {
    await _secureStorage.delete(key: _KEY_STUDENT_ACCOUNTS);
    await _secureStorage.delete(key: _KEY_ACTIVE_STUDENT_UID);
    studentAccounts.clear();
    activeStudentUid.value = null;
    print("🔒 [AuthSecureStorageService] All student accounts cleared.");
  }

  // Dapatkan akun aktif
  StudentProfilePreview? getActiveAccount() {
    if (activeStudentUid.value == null) return null;
    return studentAccounts.firstWhereOrNull((s) => s.uid == activeStudentUid.value);
  }

  // Dapatkan akun berdasarkan UID
  StudentProfilePreview? getAccountByUid(String uid) {
    return studentAccounts.firstWhereOrNull((s) => s.uid == uid);
  }
}