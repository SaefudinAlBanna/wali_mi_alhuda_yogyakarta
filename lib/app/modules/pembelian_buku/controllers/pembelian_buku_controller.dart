import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/buku_model.dart';

enum PageMode { Loading, PendaftaranDibuka, PendaftaranDitutup, Error }

class PembelianBukuController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();

  final Rx<PageMode> pageMode = PageMode.Loading.obs;
  final RxString errorMessage = "".obs;
  final Rxn<DocumentSnapshot> pendaftaranAktif = Rxn<DocumentSnapshot>();
  
  final RxList<BukuModel> daftarBuku = <BukuModel>[].obs;
  final RxMap<String, bool> bukuTerpilih = <String, bool>{}.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(configC.isKonfigurasiLoading, (isLoading) {
      if (!isLoading) loadInitialData();
    });
    if (!configC.isKonfigurasiLoading.value) loadInitialData();
  }

  Future<void> loadInitialData() async {
    pageMode.value = PageMode.Loading;
    try {
      final taAktif = configC.tahunAjaranAktif.value;
      if (taAktif.isEmpty || taAktif.contains("TIDAK")) throw Exception("Tahun ajaran belum siap.");
      
      final pendaftaranSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('pendaftaran_buku').where('status', isEqualTo: 'Dibuka').limit(1).get();

      final uidSiswa = authC.auth.currentUser!.uid;
      final pendaftarDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('pendaftaran_buku').doc(uidSiswa).get();

      if (pendaftarDoc.exists) {
        final List<dynamic> listBuku = pendaftarDoc.data()?['bukuDipilih'] ?? [];
        for (var buku in listBuku) {
          bukuTerpilih[buku['bukuId']] = true;
        }
      }

      final bukuSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif).collection('buku_ditawarkan').get();
      daftarBuku.assignAll(bukuSnap.docs.map((d) => BukuModel.fromFirestore(d)).toList());

      if (pendaftaranSnap.docs.isNotEmpty) {
        pendaftaranAktif.value = pendaftaranSnap.docs.first;
        pageMode.value = PageMode.PendaftaranDibuka;
      } else {
        pageMode.value = PageMode.PendaftaranDitutup;
      }
    } catch (e) {
      errorMessage.value = "Gagal memuat data: ${e.toString()}";
      pageMode.value = PageMode.Error;
    }
  }

  // [FUNGSI YANG DIPERBAIKI TOTAL DENGAN LOGIKA ANTI-RESET]
  Future<void> toggleBukuSelection(BukuModel buku, bool isSelected) async {
    isSaving.value = true;
    try {
      if (isSelected) bukuTerpilih[buku.id] = true;
      else bukuTerpilih.remove(buku.id);
      
      final uidSiswa = authC.auth.currentUser!.uid;
      final taAktif = configC.tahunAjaranAktif.value;
      
      final pendaftarRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('pendaftaran_buku').doc(uidSiswa);

      final List<Map<String, dynamic>> listBukuTerpilih = [];
      int totalTagihanBaru = 0;
      
      bukuTerpilih.forEach((bukuId, _) {
        final bukuDetail = daftarBuku.firstWhere((b) => b.id == bukuId);
        listBukuTerpilih.add({'bukuId': bukuId, 'namaItem': bukuDetail.namaItem, 'harga': bukuDetail.harga});
        totalTagihanBaru += bukuDetail.harga;
      });

      // Siswa HANYA mengupdate dokumen pendaftarannya sendiri.
      await pendaftarRef.set({
        'namaSiswa': configC.infoUser['namaLengkap'],
        'kelasSiswa': configC.infoUser['kelasId'],
        'bukuDipilih': listBukuTerpilih,
        'totalTagihanBuku': totalTagihanBaru,
        'timestamp': FieldValue.serverTimestamp(),
        'sudahJadiTagihan': false,
      }, SetOptions(merge: true));
      
    } catch (e) {
      Get.snackbar("Error", "Gagal memperbarui pilihan: ${e.toString()}");
      // Kembalikan state UI jika gagal
      if (isSelected) bukuTerpilih.remove(buku.id); else bukuTerpilih[buku.id] = true;
    } finally {
      isSaving.value = false;
    }
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import '../../../controllers/auth_controller.dart';
// import '../../../controllers/config_controller.dart';
// import '../../../models/buku_model.dart';

// enum PageMode { Loading, PendaftaranDibuka, PendaftaranDitutup, Error }

// class PembelianBukuController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ConfigController configC = Get.find<ConfigController>();
//   final AuthController authC = Get.find<AuthController>();

//   final Rx<PageMode> pageMode = PageMode.Loading.obs;
//   final RxString errorMessage = "".obs;
//   final Rxn<DocumentSnapshot> pendaftaranAktif = Rxn<DocumentSnapshot>();
  
//   final RxList<BukuModel> daftarBuku = <BukuModel>[].obs;
//   final RxMap<String, bool> bukuTerpilih = <String, bool>{}.obs;
//   final isSaving = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     ever(configC.isKonfigurasiLoading, (isLoading) {
//       if (!isLoading) loadInitialData();
//     });
//     if (!configC.isKonfigurasiLoading.value) loadInitialData();
//   }

//   Future<void> loadInitialData() async {
//     pageMode.value = PageMode.Loading;
//     try {
//       final taAktif = configC.tahunAjaranAktif.value;
//       if (taAktif.isEmpty || taAktif.contains("TIDAK")) throw Exception("Tahun ajaran belum siap.");
      
//       final pendaftaranSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
//           .collection('tahunajaran').doc(taAktif)
//           .collection('pendaftaran_buku').where('status', isEqualTo: 'Dibuka').limit(1).get();

//       final uidSiswa = authC.auth.currentUser!.uid;
//       final pendaftarDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah)
//           .collection('tahunajaran').doc(taAktif)
//           .collection('pendaftaran_buku').doc(uidSiswa).get();

//       if (pendaftarDoc.exists) {
//         final List<dynamic> listBuku = pendaftarDoc.data()?['bukuDipilih'] ?? [];
//         for (var buku in listBuku) {
//           bukuTerpilih[buku['bukuId']] = true;
//         }
//       }

//       final bukuSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
//           .collection('tahunajaran').doc(taAktif).collection('buku_ditawarkan').get();
//       daftarBuku.assignAll(bukuSnap.docs.map((d) => BukuModel.fromFirestore(d)).toList());

//       if (pendaftaranSnap.docs.isNotEmpty) {
//         pendaftaranAktif.value = pendaftaranSnap.docs.first;
//         pageMode.value = PageMode.PendaftaranDibuka;
//       } else {
//         pageMode.value = PageMode.PendaftaranDitutup;
//       }
//     } catch (e) {
//       errorMessage.value = "Gagal memuat data: ${e.toString()}";
//       pageMode.value = PageMode.Error;
//     }
//   }

//   Future<void> toggleBukuSelection(BukuModel buku, bool isSelected) async {
//     isSaving.value = true;
//     try {
//       if (isSelected) bukuTerpilih[buku.id] = true;
//       else bukuTerpilih.remove(buku.id);
      
//       final uidSiswa = authC.auth.currentUser!.uid;
//       final taAktif = configC.tahunAjaranAktif.value;
      
//       // Path ke dokumen pendaftaran milik siswa
//       final pendaftarRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
//           .collection('tahunajaran').doc(taAktif)
//           .collection('pendaftaran_buku').doc(uidSiswa);

//       final List<Map<String, dynamic>> listBukuTerpilih = [];
//       int totalTagihanBaru = 0;
      
//       bukuTerpilih.forEach((bukuId, _) {
//         final bukuDetail = daftarBuku.firstWhere((b) => b.id == bukuId);
//         listBukuTerpilih.add({'bukuId': bukuId, 'namaItem': bukuDetail.namaItem, 'harga': bukuDetail.harga});
//         totalTagihanBaru += bukuDetail.harga;
//       });

//       // Siswa HANYA mengupdate dokumen pendaftarannya sendiri.
//       // TIDAK ADA LAGI LOGIKA TRANSAKSI ATAU PEMBUATAN TAGIHAN DI SINI.
//       await pendaftarRef.set({
//         'namaSiswa': configC.infoUser['namaLengkap'],
//         'kelasSiswa': configC.infoUser['kelasId'],
//         'bukuDipilih': listBukuTerpilih,
//         'totalTagihanBuku': totalTagihanBaru,
//         'timestamp': FieldValue.serverTimestamp(),
//         'sudahJadiTagihan': false, // Selalu set false, nanti admin yang proses
//       }, SetOptions(merge: true));
      
//     } catch (e) {
//       Get.snackbar("Error", "Gagal memperbarui pilihan: ${e.toString()}");
//       if (isSelected) bukuTerpilih.remove(buku.id); else bukuTerpilih[buku.id] = true;
//     } finally {
//       isSaving.value = false;
//     }
//   }
// }