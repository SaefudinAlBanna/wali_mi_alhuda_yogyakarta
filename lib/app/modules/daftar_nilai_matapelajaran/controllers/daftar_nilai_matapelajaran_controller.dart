// controllers/daftar_nilai_matapelajaran_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class DaftarNilaiMatapelajaranController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String idSekolah = "P9984539";

  // State Management
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final RxList<Map<String, dynamic>> daftarNilai = <Map<String, dynamic>>[].obs;
  
  // Variabel untuk menampung data dari argumen
  late final Map<String, dynamic> mapelData;

  @override
  void onInit() {
    super.onInit();
    // Ambil argumen yang dikirim dari halaman sebelumnya
    if (Get.arguments == null) {
      errorMessage.value = "Data mata pelajaran tidak ditemukan.";
      isLoading.value = false;
      return;
    }
    mapelData = Get.arguments as Map<String, dynamic>;
    _fetchNilaiList();
  }

  Future<void> _fetchNilaiList() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Bangun path menggunakan data dari argumen
      final path = 'Sekolah/$idSekolah/tahunajaran/${mapelData['idTahunAjaran']}/kelastahunajaran/${mapelData['idKelas']}/daftarsiswa/${mapelData['nisn']}/semester/${mapelData['idSemester']}/matapelajaran/${mapelData['idMapel']}/nilai';
      
      final snapshot = await firestore.collection(path).orderBy('tanggal', descending: true).get();

      if (snapshot.docs.isEmpty) {
        // Tetap set list kosong, UI akan menampilkan pesan
        daftarNilai.value = [];
      } else {
        daftarNilai.value = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      }
    } catch (e) {
      errorMessage.value = "Terjadi kesalahan saat memuat data nilai: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }
}