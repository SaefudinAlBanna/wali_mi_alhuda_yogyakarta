// lib/app/modules/daftar_mata_pelajaran/controllers/daftar_mata_pelajaran_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/mapel_siswa_model.dart';
import '../../../routes/app_pages.dart';

class DaftarMataPelajaranController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController authC = Get.find<AuthController>();
  final ConfigController configC = Get.find<ConfigController>();

  // [DIHAPUS] State tahunAjaranAktif, semesterAktif, isKonfigurasiLoading di sini tidak lagi dibutuhkan.
  // Gunakan langsung dari configC.

  @override
  void onInit() {
    super.onInit();
    // Gunakan listener untuk memastikan data configC sudah siap
    ever(configC.isKonfigurasiLoading, (bool isLoadingConfig) {
      if (!isLoadingConfig) {
        // Pemicu pengambilan data jika sudah terautentikasi dan konfigurasi siap
        if (authC.auth.currentUser == null || configC.tahunAjaranAktif.value.isEmpty || configC.tahunAjaranAktif.value.contains("TIDAK")) {
          Get.snackbar("Peringatan", "Data akademik atau sesi pengguna belum siap. Silakan coba lagi.");
        }
        // FutureBuilder di view akan memicu getMataPelajaranSiswa()
      }
    });
    // Jika sudah ready saat onInit, panggil pemicu awal
    if (!configC.isKonfigurasiLoading.value && authC.auth.currentUser != null && configC.tahunAjaranAktif.value.isNotEmpty && !configC.tahunAjaranAktif.value.contains("TIDAK")) {
        // FutureBuilder di view akan memicu getMataPelajaranSiswa()
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getMataPelajaranSiswa() {
    final uid = authC.auth.currentUser?.uid;
    final kelasId = configC.infoUser['kelasId'] as String?; // Diperlukan untuk path yang benar

    // Langsung gunakan dari configC
    final tahunAjaran = configC.tahunAjaranAktif.value;
    final semester = configC.semesterAktif.value;

    if (uid == null || kelasId == null || kelasId.isEmpty || tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK") || semester.isEmpty) {
      return Future.error("Data konfigurasi atau sesi pengguna tidak lengkap.");
    }
    
    // --- [PERBAIKAN KUNCI] Path diubah ke path lengkap yang sebenarnya ada di Firestore ---
    return _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('kelastahunajaran').doc(kelasId)
        .collection('daftarsiswa').doc(uid)
        .collection('semester').doc(semester)
        .collection('matapelajaran')
        .orderBy('namaMapel')
        .get(); 
  }
  
  void goToDetailMapel(MapelSiswaModel mapel) {
    Get.toNamed(
      Routes.DETAIL_MAPEL_SISWA,
      arguments: {
        'idMapel': mapel.id,
        'namaMapel': mapel.namaMapel,
        'namaGuru': mapel.namaGuru,
        'aliasGuru': mapel.aliasGuru,
        'tahunAjaran': configC.tahunAjaranAktif.value,
        'semester': configC.semesterAktif.value,
        'kelasId': configC.infoUser['kelasId'],
      }
    );
  }
}



// // lib/app/modules/daftar_mata_pelajaran/controllers/daftar_mata_pelajaran_controller.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';

// import '../../../controllers/auth_controller.dart';
// import '../../../controllers/config_controller.dart';
// import '../../../models/mapel_siswa_model.dart';
// import '../../../routes/app_pages.dart';

// class DaftarMataPelajaranController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final AuthController authC = Get.find<AuthController>();
//   final ConfigController configC = Get.find<ConfigController>();

//   final RxString tahunAjaranAktif = "".obs;
//   final RxString semesterAktif = "".obs;
//   final RxBool isKonfigurasiLoading = true.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     _fetchKonfigurasiAkademik();
//   }

//   Future<void> _fetchKonfigurasiAkademik() async {
//     try {
//       isKonfigurasiLoading.value = true;
//       final snapshot = await _firestore
//           .collection('Sekolah').doc(configC.idSekolah)
//           .collection('tahunajaran')
//           .where('isAktif', isEqualTo: true)
//           .limit(1)
//           .get();

//       if (snapshot.docs.isNotEmpty) {
//         final doc = snapshot.docs.first;
//         tahunAjaranAktif.value = doc.id;
//         semesterAktif.value = doc.data()['semesterAktif']?.toString() ?? '1';
//       } else {
//         tahunAjaranAktif.value = "TIDAK_AKTIF";
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Gagal memuat konfigurasi akademik.");
//       tahunAjaranAktif.value = "ERROR";
//     } finally {
//       isKonfigurasiLoading.value = false;
//     }
//   }

//   Future<QuerySnapshot<Map<String, dynamic>>> getMataPelajaranSiswa() {
//     final uid = authC.auth.currentUser?.uid;
//     final kelasId = configC.infoUser['kelasId'] as String?;

//     if (uid == null || kelasId == null || kelasId.isEmpty || tahunAjaranAktif.value.isEmpty || tahunAjaranAktif.value.contains("TIDAK_AKTIF")) {
//       return Future.error("Data konfigurasi tidak lengkap.");
//     }
    
//     // --- [FIX] Path diubah ke koleksi spesifik milik siswa ---
//     return _firestore
//         .collection('Sekolah').doc(configC.idSekolah)
//         .collection('tahunajaran').doc(tahunAjaranAktif.value)
//         .collection('kelastahunajaran').doc(kelasId)
//         .collection('semester').doc(semesterAktif.value)
//         .collection('daftarsiswa').doc(uid)
//         .collection('matapelajaran')
//         .orderBy('namaMapel')
//         .get(); 
//   }
  
//   void goToDetailMapel(MapelSiswaModel mapel) {
//     // Navigasi ke Halaman Detail (Tahap 2)
//     // Untuk sekarang, kita beri Snackbar
//     Get.toNamed(
//       Routes.DETAIL_MAPEL_SISWA, // Ini akan kita buat di Tahap 2
//       arguments: {
//         'idMapel': mapel.id,
//         'namaMapel': mapel.namaMapel,
//         'namaGuru': mapel.namaGuru,
//         'tahunAjaran': tahunAjaranAktif.value,
//         'semester': semesterAktif.value,
//         'kelasId': configC.infoUser['kelasId'],
//       }
//     );
//   }
// }