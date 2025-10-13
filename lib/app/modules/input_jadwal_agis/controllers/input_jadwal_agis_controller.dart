import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../models/siswa_kelas_model.dart';
import '../../jadwal_agis/controllers/jadwal_agis_controller.dart'; // Untuk refresh halaman sebelumnya

class InputJadwalAgisController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final String idSekolah = "P9984539";

  // --- State untuk UI ---
  var isLoading = true.obs;
  var isAuthorized = false.obs;
  var isSaving = false.obs;
  
  // --- Data Kelas & Siswa ---
  late String idKelas;
  late String tahunAjaran;
  var daftarSiswa = <SiswaKelasModel>[].obs;

  // --- Form State ---
  var selectedDate = Rx<DateTime?>(null);
  var selectedSiswa = Rx<SiswaKelasModel?>(null);
  final keteranganController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initializePage();
  }

  Future<void> _initializePage() async {
    isLoading.value = true;
    try {
      // 1. Verifikasi apakah user adalah admin
      final profilAdmin = await _getProfilAdmin();
      if (profilAdmin['isAdminAgis'] != true) {
        isAuthorized.value = false;
        throw Exception("Anda tidak memiliki hak akses sebagai Admin AGIS.");
      }
      isAuthorized.value = true;
      
      // 2. Dapatkan data esensial (tahun ajaran & kelas)
      tahunAjaran = await _getTahunAjaranTerakhir();
      idKelas = await _getKelasSiswa(profilAdmin['nisn'], tahunAjaran);

      // 3. Ambil daftar siswa di kelas tersebut
      await _fetchDaftarSiswa();

    } catch (e) {
      Get.snackbar(
        "Error", e.toString().replaceAll("Exception: ", ""),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<Map<String, dynamic>> _getProfilAdmin() async {
    final user = auth.currentUser;
    if (user == null) throw Exception("Tidak ada pengguna yang login.");

    final doc = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('siswa').where('uid', isEqualTo: user.uid).limit(1).get();

    if (doc.docs.isEmpty) throw Exception("Data siswa tidak ditemukan.");
    final siswaData = doc.docs.first.data();
    
    // Asumsi ada field 'isAdminAgis' di dokumen siswa
    return {'nisn': doc.docs.first.id, 'isAdminAgis': siswaData['isAdminAgis'] ?? false};
  }

  Future<void> _fetchDaftarSiswa() async {
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('kelastahunajaran').doc(idKelas)
        .collection('daftarsiswa')
        .get();

    if (snapshot.docs.isEmpty) throw Exception("Tidak ada siswa di kelas ini.");
    
    daftarSiswa.value = snapshot.docs.map((doc) => SiswaKelasModel.fromFirestore(doc.id, doc.data())).toList();
    // Urutkan berdasarkan nama
    daftarSiswa.sort((a, b) => a.nama.compareTo(b.nama));
  }
  
  void pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      // firstDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'PILIH TANGGAL JADWAL',
      builder: (context, child) {
        // Optional: Theming agar sesuai dengan tema aplikasi
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple, // warna header
              onPrimary: Colors.white, // warna teks di header
              onSurface: Colors.black, // warna teks tanggal
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple, // warna tombol OK/Cancel
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      // Untuk memastikan kita tidak menyimpan informasi jam, menit, detik
      // Ini mencegah bug perbandingan zona waktu.
      selectedDate.value = DateTime(date.year, date.month, date.day);
    }
  }

  void simpanJadwal() async {
    if (selectedDate.value == null || selectedSiswa.value == null) {
      Get.snackbar("Gagal", "Tanggal dan Siswa harus dipilih.", backgroundColor: Colors.orange);
      return;
    }
    
    isSaving.value = true;
    try {
      // ID dokumen adalah tanggal (YYYY-MM-DD) agar unik per hari
      String docId = DateFormat('yyyy-MM-dd').format(selectedDate.value!);
      
      final dataToSave = {
        'tanggal': Timestamp.fromDate(selectedDate.value!),
        'nisn_bertugas': selectedSiswa.value!.nisn,
        'nama_siswa': selectedSiswa.value!.nama,
        'keterangan': keteranganController.text.isNotEmpty ? keteranganController.text : 'Snack Pilihan',
      };
      
      await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('kelastahunajaran').doc(idKelas)
        .collection('jadwalAgis').doc(docId)
        .set(dataToSave); // .set() untuk create atau update

      Get.snackbar("Berhasil", "Jadwal untuk ${selectedSiswa.value!.nama} berhasil disimpan.", backgroundColor: Colors.green, colorText: Colors.white);
      
      // Refresh halaman sebelumnya jika terbuka
      if (Get.isRegistered<JadwalAgisController>()) {
        Get.find<JadwalAgisController>().fetchJadwalAgis();
      }

      // Reset form
      selectedDate.value = null;
      selectedSiswa.value = null;
      keteranganController.clear();
      
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan: ${e.toString()}", backgroundColor: Colors.red);
    } finally {
      isSaving.value = false;
    }
  }
  
  // Fungsi helper dari controller sebelumnya
  Future<String> _getTahunAjaranTerakhir() async { /* ... (sama seperti di JadwalAgisController) ... */ return "2024-2025"; }
  Future<String> _getKelasSiswa(String nisn, String tahunAjaran) async { /* ... (sama seperti di JadwalAgisController) ... */ return "1A"; }

  @override
  void onClose() {
    keteranganController.dispose();
    super.onClose();
  }
}