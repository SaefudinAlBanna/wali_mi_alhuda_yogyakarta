// lib/app/modules/ekskul_siswa/controllers/ekskul_siswa_controller.dart (Aplikasi ORANG TUA)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/ekskul_model.dart';

enum PageMode { Loading, PendaftaranDibuka, PendaftaranDitutup, Error }

class EkskulSiswaController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();

  final Rx<PageMode> pageMode = PageMode.Loading.obs;
  final RxString errorMessage = "".obs;
  final Rxn<DocumentSnapshot> pendaftaranAktif = Rxn<DocumentSnapshot>();
  
  final RxList<EkskulModel> daftarEkskul = <EkskulModel>[].obs;
  final RxMap<String, bool> ekskulTerpilih = <String, bool>{}.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    // [PERBAIKAN KUNCI] Panggil loadInitialData HANYA setelah ConfigController selesai memuat konfigurasi
    ever(configC.isKonfigurasiLoading, (bool isLoadingConfig) {
      if (!isLoadingConfig && pageMode.value == PageMode.Loading) { // Hanya panggil sekali saat selesai loading
        loadInitialData();
      }
    });
    // Jika sudah selesai loading saat onInit dipanggil, panggil langsung
    if (!configC.isKonfigurasiLoading.value && pageMode.value == PageMode.Loading) {
      loadInitialData();
    }
  }

  Future<void> loadInitialData() async {
    // Pastikan ini tidak berulang kali dipanggil jika sudah selesai
    if (pageMode.value != PageMode.Loading) return;

    pageMode.value = PageMode.Loading; // Pastikan status loading di awal
    try {
      // Pastikan tahun ajaran dan semester sudah terisi dari ConfigController
      final String tahunAjaran = configC.tahunAjaranAktif.value;
      final String semester = configC.semesterAktif.value;

      if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK") || semester.isEmpty) {
        errorMessage.value = "Konfigurasi tahun ajaran atau semester belum siap.";
        pageMode.value = PageMode.Error;
        print("### EKSKUL ERROR: $errorMessage");
        return;
      }
      
      final pendaftaranSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('ekskul_pendaftaran')
          .where('status', isEqualTo: 'Dibuka').limit(1).get();

      final siswaDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('siswa').doc(authC.auth.currentUser!.uid).get();
      final Map<String, dynamic> ekskulTerdaftarMap = (siswaDoc.data()?['ekskulTerdaftar'] as Map<String, dynamic>?) ?? {};
      ekskulTerpilih.assignAll(Map<String, bool>.from(ekskulTerdaftarMap));

      if (pendaftaranSnap.docs.isNotEmpty) {
        pendaftaranAktif.value = pendaftaranSnap.docs.first;
        pageMode.value = PageMode.PendaftaranDibuka;
        final ekskulSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('ekskul_ditawarkan')
            .where('tahunAjaran', isEqualTo: tahunAjaran)
            .where('semester', isEqualTo: semester).get();
        daftarEkskul.assignAll(ekskulSnap.docs.map((d) => EkskulModel.fromFirestore(d)).toList());
      } else {
        pageMode.value = PageMode.PendaftaranDitutup;
        final List<String> idTerdaftar = ekskulTerpilih.keys.toList();
        if (idTerdaftar.isNotEmpty) {
          final ekskulSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
              .collection('ekskul_ditawarkan').where(FieldPath.documentId, whereIn: idTerdaftar).get();
          daftarEkskul.assignAll(ekskulSnap.docs.map((d) => EkskulModel.fromFirestore(d)).toList());
        } else {
          daftarEkskul.clear();
        }
      }
    } catch (e) { 
      errorMessage.value = "Gagal memuat data ekskul: ${e.toString()}";
      pageMode.value = PageMode.Error;
      print("### EKSKUL ERROR: $e");
    }
  }

  Future<void> toggleEkskulSelection(EkskulModel ekskul, bool isSelected) async {
    // [PERBAIKAN] Tambahkan pengecekan null untuk pendaftaranAktif
    if (pendaftaranAktif.value == null) {
      Get.snackbar("Peringatan", "Pendaftaran tidak aktif. Tidak bisa memperbarui pilihan ekskul.");
      return;
    }

    isSaving.value = true;
    try {
      final uid = authC.auth.currentUser!.uid;
      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(uid);
      final pendaftaranRef = pendaftaranAktif.value!.reference;
      final WriteBatch batch = _firestore.batch();
      
      if (isSelected) {
        ekskulTerpilih[ekskul.id] = true;
        batch.update(siswaRef, {'ekskulTerdaftar.${ekskul.id}': true});
        // [PERBAIKAN] Pastikan path ke ekskulDipilih sesuai dengan rules dan model
        batch.update(pendaftaranRef, {'ekskulDipilih.${ekskul.id}': FieldValue.arrayUnion([uid])});
      } else {
        ekskulTerpilih.remove(ekskul.id);
        batch.update(siswaRef, {'ekskulTerdaftar.${ekskul.id}': FieldValue.delete()});
        // [PERBAIKAN] Pastikan path ke ekskulDipilih sesuai dengan rules dan model
        batch.update(pendaftaranRef, {'ekskulDipilih.${ekskul.id}': FieldValue.arrayRemove([uid])});
      }
      
      await batch.commit();
      Get.snackbar("Berhasil", isSelected ? "Terdaftar di ${ekskul.namaEkskul}" : "Pendaftaran ${ekskul.namaEkskul} dibatalkan");
    } catch (e) { 
      Get.snackbar("Error", "Gagal memperbarui pilihan: ${e.toString()}"); 
      print("### EKSKUL TOGGLE ERROR: $e");
    }
    finally { isSaving.value = false; }
  }
}