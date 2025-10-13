import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Tambahkan package intl: flutter pub add intl
import '../../../models/jadwal_agis_model.dart'; // Import model yang baru dibuat


// Controller ini akan berisi semua logika untuk mengambil data dari Firestore. 
// Kita akan gunakan StateMixin dari GetX untuk menangani state loading, data, dan error secara otomatis.


class JadwalAgisController extends GetxController with StateMixin<List<JadwalAgisModel>> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  final String idSekolah = "P9984539"; // Hardcoded sesuai permintaan

  // Untuk menyimpan data yang relevan
  RxString nisnSiswa = ''.obs;
  RxString namaSiswa = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchJadwalAgis();
  }

  // Future<void> fetchJadwalAgis() async {
  //   // 1. Tampilkan status loading di UI
  //   change([], status: RxStatus.loading());

  //   try {
  //     // 2. Ambil data siswa yang sedang login
  //     final Map<String, dynamic> dataSiswa = await _getProfilSiswa();
  //     nisnSiswa.value = dataSiswa['nisn'];
  //     namaSiswa.value = dataSiswa['nama'];

  //     // 3. Ambil tahun ajaran terakhir
  //     final String tahunAjaran = await getTahunAjaranTerakhir();

  //     // 4. Ambil kelas siswa di tahun ajaran tersebut
  //     final String idKelas = await getKelasSiswa(nisnSiswa.value, tahunAjaran);

  //     // 5. Ambil data jadwal dari Firestore berdasarkan path yang disarankan
  //     final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
  //         .collection('Sekolah').doc(idSekolah)
  //         .collection('tahunajaran').doc(tahunAjaran)
  //         .collection('kelastahunajaran').doc(idKelas)
  //         .collection('jadwalAgis')
  //         .where('tanggal', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 7))) // Ambil data dari 7 hari lalu
  //         .orderBy('tanggal', descending: false)
  //         .get();

  //     if (snapshot.docs.isEmpty) {
  //       // 6a. Jika tidak ada data, tampilkan pesan kosong
  //       change([], status: RxStatus.empty());
  //     } else {
  //       // 6b. Jika ada, ubah data firestore menjadi List<JadwalAgisModel>
  //       final listJadwal = snapshot.docs.map((doc) => JadwalAgisModel.fromFirestore(doc)).toList();
  //       change(listJadwal, status: RxStatus.success());
  //     }
  //   } catch (e) {
  //     // 7. Jika terjadi error, tampilkan pesan error
  //     printError(info: e.toString());
  //     change([], status: RxStatus.error("Gagal memuat jadwal: ${e.toString()}"));
  //   }
  // }

  Future<void> fetchJadwalAgis() async {
    change([], status: RxStatus.loading());

    try {
      final Map<String, dynamic> dataSiswa = await _getProfilSiswa();
      nisnSiswa.value = dataSiswa['nisn'];
      namaSiswa.value = dataSiswa['nama'];

      final String tahunAjaran = await getTahunAjaranTerakhir();
      final String idKelas = await getKelasSiswa(nisnSiswa.value, tahunAjaran);

      // Ambil data jadwal dari Firestore
      // Query diubah sedikit, ambil data mulai dari awal hari ini.
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);

      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('jadwalAgis')
          .where('tanggal', isGreaterThanOrEqualTo: startOfToday) // Ambil jadwal mulai hari ini dan ke depan
          .orderBy('tanggal', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        change([], status: RxStatus.empty());
      } else {
        final listJadwal = snapshot.docs.map((doc) => JadwalAgisModel.fromFirestore(doc)).toList();
        
        // --- LOGIKA BARU UNTUK PIN JADWAL ---
        // 1. Siapkan dua list kosong
        final jadwalMilikSiswa = <JadwalAgisModel>[];
        final jadwalLainnya = <JadwalAgisModel>[];

        // 2. Pisahkan jadwal berdasarkan kepemilikan
        for (var jadwal in listJadwal) {
          if (jadwal.nisnBertugas == nisnSiswa.value) {
            jadwalMilikSiswa.add(jadwal);
          } else {
            jadwalLainnya.add(jadwal);
          }
        }
        
        // 3. Gabungkan kembali dengan jadwal siswa di paling atas
        final sortedList = [...jadwalMilikSiswa, ...jadwalLainnya];
        // ------------------------------------

        change(sortedList, status: RxStatus.success());
      }
    } catch (e) {
      printError(info: e.toString());
      change([], status: RxStatus.error("Gagal memuat jadwal: ${e.toString()}"));
    }
  }

  // --- HELPER FUNCTIONS (Diadaptasi dari kode Anda) ---

  Future<Map<String, dynamic>> _getProfilSiswa() async {
    final User? user = auth.currentUser;
    if (user == null) throw Exception("Tidak ada pengguna yang login.");

    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('siswa')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) throw Exception("Data siswa tidak ditemukan.");
    
    // Mengembalikan ID (nisn) dan nama siswa
    return {
      'nisn': snapshot.docs.first.id,
      'nama': snapshot.docs.first.data()['namaLengkap'] ?? 'Tanpa Nama', // asumsikan field nama adalah 'namaLengkap'
    };
  }

  Future<String> getTahunAjaranTerakhir() async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran')
        .orderBy('namatahunajaran', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) throw Exception("Tidak ada data tahun ajaran");
    return snapshot.docs.first.id;
  }

  Future<String> getKelasSiswa(String nisn, String tahunAjaran) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('siswa').doc(nisn)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('kelasnya')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) throw Exception("Data kelas tidak ditemukan.");
    return snapshot.docs.first.id;
  }

  // Helper untuk format tanggal
  String formatTanggal(DateTime date) {
    // Menggunakan package intl untuk format Bahasa Indonesia
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  // Helper untuk mengecek apakah hari ini
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
