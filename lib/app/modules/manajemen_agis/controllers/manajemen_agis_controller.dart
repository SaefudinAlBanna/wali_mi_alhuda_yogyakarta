// lib/app/modules/manajemen_agis/controllers/manajemen_agis_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controllers/account_manager_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/agis_jadwal_model.dart';
import '../../../models/siswa_selection_model.dart';

class ManajemenAgisController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AccountManagerController accountManagerC = Get.find<AccountManagerController>();

  final isLoading = true.obs;
  final isProcessing = false.obs;
  final isPjAgis = false.obs;

  final RxList<AgisJadwalModel> jadwalMingguIni = <AgisJadwalModel>[].obs;
  final Rx<DateTime> tanggalAwalMinggu = DateTime.now().obs;
  final RxString catatanUmumAgis = "Tidak ada catatan.".obs;
  
  final RxList<SiswaSelectionModel> _daftarSiswaKelas = <SiswaSelectionModel>[].obs;
  final RxList<SiswaSelectionModel> hasilPencarian = <SiswaSelectionModel>[].obs;
  final searchC = TextEditingController();

  DocumentReference? _catatanConfigRef;

  @override
  void onInit() {
    super.onInit();
    _calculateMonday();
    ever(tanggalAwalMinggu, (_) => _checkAuthorizationAndFetchData());
    _checkAuthorizationAndFetchData();
  }

  void _calculateMonday() {
    final now = DateTime.now();
    tanggalAwalMinggu.value = now.subtract(Duration(days: now.weekday - 1));
  }

  Future<void> _checkAuthorizationAndFetchData() async {
    isLoading.value = true;
    final peranKomite = accountManagerC.currentActiveStudent.value?.peranKomite;
    isPjAgis.value = peranKomite?['jabatan'] == 'PJ AGIS';
    
    if (isPjAgis.value) {
      await _fetchDaftarSiswaKelas();
    }
    await _fetchJadwalDanCatatan();
    isLoading.value = false;
  }

  Future<void> _fetchDaftarSiswaKelas() async {
    try {
      final kelasId = accountManagerC.currentActiveStudent.value!.kelasId;
      final taAktif = configC.tahunAjaranAktif.value;
      
      final siswaSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('kelastahunajaran').doc(kelasId)
          .collection('daftarsiswa').get();

      _daftarSiswaKelas.assignAll(siswaSnap.docs.map((d) {
        return SiswaSelectionModel(
          uid: d.id,
          nama: d.data()['namaLengkap'] ?? 'Tanpa Nama',
          kelasId: d.data()['kelasId'] ?? 'N/A',
        );
      }).toList());
    } catch (e) {
      Get.snackbar("Peringatan", "Gagal memuat daftar siswa untuk pemilihan.");
    }
  }

  Future<void> _fetchJadwalDanCatatan() async {
    try {
      final kelasId = accountManagerC.currentActiveStudent.value!.kelasId;
      final taAktif = configC.tahunAjaranAktif.value;

      final kelastahunajaranRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('kelastahunajaran').doc(kelasId);
      
      _catatanConfigRef = kelastahunajaranRef.collection('pengaturan_kelas').doc('komite_config');

      final start = tanggalAwalMinggu.value;
      final end = start.add(const Duration(days: 5));

      final results = await Future.wait([
        kelastahunajaranRef.collection('jadwal_agis')
          .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('tanggal', isLessThan: Timestamp.fromDate(end)).get(),
        _catatanConfigRef!.get()
      ]);
      
      final jadwalSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
      jadwalMingguIni.assignAll(jadwalSnap.docs.map((d) => AgisJadwalModel.fromFirestore(d)).toList());
      
      final catatanSnap = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      if (catatanSnap.exists) {
        catatanUmumAgis.value = catatanSnap.data()?['catatanUmumAgis'] ?? 'Tidak ada catatan.';
      }

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat jadwal AGIS: ${e.toString()}");
    }
  }
  
  void gantiMinggu(int weeks) {
    tanggalAwalMinggu.value = tanggalAwalMinggu.value.add(Duration(days: 7 * weeks));
  }

  // [DIUBAH] Fungsi disederhanakan, hanya memilih siswa
  Future<void> aturJadwal(DateTime tanggal) async {
    final SiswaSelectionModel? siswaTerpilih = await _showSiswaSearchDialog();
    if (siswaTerpilih == null) return;

    isProcessing.value = true;
    try {
      final kelasId = accountManagerC.currentActiveStudent.value!.kelasId;
      final taAktif = configC.tahunAjaranAktif.value;
      final jadwalId = DateFormat('yyyy-MM-dd').format(tanggal);
      final pjAgis = accountManagerC.currentActiveStudent.value!;

      final jadwalRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('kelastahunajaran').doc(kelasId)
          .collection('jadwal_agis').doc(jadwalId);

      await jadwalRef.set({
        'tanggal': Timestamp.fromDate(tanggal),
        'uidSiswaBertugas': siswaTerpilih.uid,
        'namaSiswaBertugas': siswaTerpilih.nama,
        'dibuatOlehUid': pjAgis.uid,
        'timestamp': FieldValue.serverTimestamp()
      });
      
      await _fetchJadwalDanCatatan();
    } catch (e) {
      Get.snackbar("Error", "Gagal mengatur jadwal: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }

  // [FUNGSI BARU] Untuk mengedit catatan umum
  Future<void> editCatatanUmum() async {
    final catatanC = TextEditingController(text: catatanUmumAgis.value);
    
    final String? hasil = await Get.dialog(
      AlertDialog(
        title: const Text("Ubah Catatan Umum AGIS"),
        content: TextField(
          controller: catatanC,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Tulis catatan di sini...",
            border: OutlineInputBorder()
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(onPressed: () => Get.back(result: catatanC.text), child: const Text("Simpan")),
        ],
      )
    );

    if (hasil != null) {
      isProcessing.value = true;
      try {
        await _catatanConfigRef!.set({'catatanUmumAgis': hasil}, SetOptions(merge: true));
        catatanUmumAgis.value = hasil;
        Get.snackbar("Berhasil", "Catatan umum berhasil diperbarui.");
      } catch (e) {
        Get.snackbar("Error", "Gagal menyimpan catatan: ${e.toString()}");
      } finally {
        isProcessing.value = false;
      }
    }
  }

  Future<void> hapusJadwal(String jadwalId) async {
    isProcessing.value = true;
     try {
      final kelasId = accountManagerC.currentActiveStudent.value!.kelasId;
      final taAktif = configC.tahunAjaranAktif.value;
      
      await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('kelastahunajaran').doc(kelasId)
          .collection('jadwal_agis').doc(jadwalId).delete();

      await _fetchJadwalDanCatatan();
    } catch (e) {
      Get.snackbar("Error", "Gagal menghapus jadwal: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }

  void _filterSiswaDialog() {
    final query = searchC.text.toLowerCase();
    if (query.isEmpty) {
      hasilPencarian.assignAll(_daftarSiswaKelas);
    } else {
      hasilPencarian.assignAll(_daftarSiswaKelas.where((siswa) {
        return siswa.nama.toLowerCase().contains(query);
      }));
    }
  }

  Future<SiswaSelectionModel?> _showSiswaSearchDialog() async {
    searchC.clear();
    hasilPencarian.assignAll(_daftarSiswaKelas);
    searchC.addListener(_filterSiswaDialog);

    final result = await Get.dialog(
      AlertDialog(
        title: const Text("Pilih Siswa Bertugas"),
        content: SizedBox(
          width: Get.width * 0.9,
          height: Get.height * 0.6,
          child: Column(
            children: [
              TextField(
                controller: searchC,
                autofocus: true,
                decoration: const InputDecoration(labelText: "Cari nama siswa..."),
              ),
              Expanded(
                child: Obx(() => ListView.builder(
                  itemCount: hasilPencarian.length,
                  itemBuilder: (context, index) {
                    final siswa = hasilPencarian[index];
                    return ListTile(
                      title: Text(siswa.nama),
                      onTap: () => Get.back(result: siswa),
                    );
                  },
                )),
              ),
            ],
          ),
        ),
      ),
    );
    searchC.removeListener(_filterSiswaDialog);
    return result;
  }
}