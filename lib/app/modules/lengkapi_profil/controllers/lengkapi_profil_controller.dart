// lib/app/modules/lengkapi_profil/controllers/lengkapi_profil_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../routes/app_pages.dart';

class LengkapiProfilController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- State ---
  final isLoading = false.obs;
  final Rx<String> jenisKelamin = "Laki-Laki".obs;

  // --- Text Controllers ---
  // Data Pribadi Siswa
  late TextEditingController namaPanggilanC;
  late TextEditingController tempatLahirC;
  late TextEditingController tanggalLahirC;
  // final Rx<String?> jenisKelamin = Rx<String?>(null);

  // Data Orang Tua
  late TextEditingController namaAyahC;
  late TextEditingController noHpAyahC;
  late TextEditingController namaIbuC;
  late TextEditingController noHpIbuC;
  late TextEditingController alamatC;

   @override
  void onInit() {
    super.onInit();
    // Inisialisasi semua controller teks
    namaPanggilanC = TextEditingController();
    tempatLahirC = TextEditingController();
    tanggalLahirC = TextEditingController();
    namaAyahC = TextEditingController();
    noHpAyahC = TextEditingController();
    namaIbuC = TextEditingController();
    noHpIbuC = TextEditingController();
    alamatC = TextEditingController();

    // --- LOGIKA BARU: Cek jika ada argumen (mode edit) ---
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      final data = Get.arguments as Map<String, dynamic>;
      
      // Isi semua field dengan data yang ada
      namaPanggilanC.text = data['namaPanggilan'] ?? '';
      tempatLahirC.text = data['tempatLahir'] ?? '';
      
      if (data['tanggalLahir'] != null) {
        try {
          tanggalLahirC.text = DateFormat('dd-MM-yyyy').format(DateTime.parse(data['tanggalLahir']));
        } catch (e) { /* biarkan kosong jika format salah */ }
      }

      jenisKelamin.value = data['jenisKelamin'];
      namaAyahC.text = data['namaAyah'] ?? '';
      noHpAyahC.text = data['noHpAyah'] ?? '';
      namaIbuC.text = data['namaIbu'] ?? '';
      noHpIbuC.text = data['noHpIbu'] ?? '';
      alamatC.text = data['alamatLengkap'] ?? '';
    }
  }

  @override
  void onClose() {
    namaPanggilanC.dispose();
    tempatLahirC.dispose();
    tanggalLahirC.dispose();
    namaAyahC.dispose();
    noHpAyahC.dispose();
    namaIbuC.dispose();
    noHpIbuC.dispose();
    alamatC.dispose();
    super.onClose();
  }

  void pilihTanggal(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      tanggalLahirC.text = DateFormat('dd-MM-yyyy').format(pickedDate);
    }
  }

  Future<void> simpanProfil() async {
    // 1. Validasi form
    if (!formKey.currentState!.validate()) {
      Get.snackbar('Input Tidak Lengkap', 'Mohon isi semua data yang wajib diisi.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    isLoading.value = true;
    try {
      // 2. Persiapkan data untuk disimpan
      final dataToUpdate = {
        'namaPanggilan': namaPanggilanC.text.trim(),
        'tempatLahir': tempatLahirC.text.trim(),
        'tanggalLahir': Timestamp.fromDate(DateFormat('dd-MM-yyyy').parse(tanggalLahirC.text)),
        'jenisKelamin': jenisKelamin.value,
        'namaAyah': namaAyahC.text.trim(),
        'noHpAyah': noHpAyahC.text.trim(),
        'namaIbu': namaIbuC.text.trim(),
        'noHpIbu': noHpIbuC.text.trim(),
        'alamatLengkap': alamatC.text.trim(),
        'isProfileComplete': true,
      };

      // 3. Simpan ke Firestore
      await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').doc(_auth.currentUser!.uid)
          .update(dataToUpdate);

      // --- [PERBAIKAN ALUR KERJA] ---
      
      // 4. Hancurkan cache profil yang lama
      await configC.clearCache();

      // 5. Tampilkan dialog sukses yang informatif dan memaksa aksi
      Get.defaultDialog(
        title: "Pendaftaran Selesai!",
        middleText: "Data profil Anda telah berhasil disimpan. Silakan masuk kembali dengan password baru Anda untuk melanjutkan.",
        textConfirm: "OK, Mengerti",
        confirmTextColor: Colors.white,
        onConfirm: () async {
          // 6. Lakukan logout penuh
          await Get.find<AuthController>().logout();
        },
        barrierDismissible: false, // Pengguna tidak bisa menutup dialog ini
      );
      // --- AKHIR PERBAIKAN ---

    } on FormatException {
      Get.snackbar('Format Salah', 'Format tanggal lahir tidak valid. Mohon gunakan format dd-MM-yyyy.');
    } catch (e) {
      Get.snackbar('Gagal', 'Tidak dapat menyimpan profil. Terjadi kesalahan: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  String? validator(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName wajib diisi.';
    return null;
  }
}