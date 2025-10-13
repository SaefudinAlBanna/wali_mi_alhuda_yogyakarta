// lib/app/modules/manajemen_komite_sekolah/controllers/manajemen_komite_sekolah_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/account_manager_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/komite_anggota_model.dart';
import '../../../models/siswa_selection_model.dart';

class ManajemenKomiteSekolahController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AccountManagerController accountManagerC = Get.find<AccountManagerController>();

  final isLoading = true.obs;
  final isProcessing = false.obs;
  final isAuthorized = false.obs;

  final RxList<KomiteAnggotaModel> anggotaKomiteSekolah = <KomiteAnggotaModel>[].obs;

  final RxList<SiswaSelectionModel> _daftarSiswaMaster = <SiswaSelectionModel>[].obs;
  final RxList<SiswaSelectionModel> hasilPencarian = <SiswaSelectionModel>[].obs;
  final searchC = TextEditingController();

  @override
  void onReady() {
    super.onReady();
    _initialize();
  }

  Future<void> _initialize() async {
    isLoading.value = true;
    _checkAuthorization();
    if (isAuthorized.value) {
      await _fetchDaftarSiswaMaster();
      await fetchData();
    }
    isLoading.value = false;
  }
  
  void _checkAuthorization() {
    final peranKomite = accountManagerC.currentActiveStudent.value?.peranKomite;
    if (peranKomite != null && peranKomite['jabatan'] == 'Ketua Komite Sekolah') {
      isAuthorized.value = true;
    } else {
      isAuthorized.value = false;
    }
  }

  Future<void> _fetchDaftarSiswaMaster() async {
    try {
      final snap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').where('statusSiswa', isEqualTo: 'Aktif').get();
      
      _daftarSiswaMaster.assignAll(snap.docs.map((d) {
        final data = d.data();
        return SiswaSelectionModel(
          uid: d.id,
          nama: data['namaLengkap'] ?? 'Tanpa Nama',
          namaOrangTua: data['namaOrangTuaTampil'] ?? 'Wali ${data['namaLengkap'] ?? ''}',
          kelasId: data['kelasId'] ?? 'N/A',
        );
      }));
    } catch (e) {
      Get.snackbar("Peringatan", "Gagal memuat daftar siswa untuk pencarian: ${e.toString()}");
    }
  }

  Future<void> fetchData() async {
    isProcessing.value = true;
    try {
      final taAktif = configC.tahunAjaranAktif.value;
      final snap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('komite').doc('sekolah')
          .collection('anggota').orderBy('jabatan').get();
  
      // [PERBAIKAN DIMULAI]
      // Kita akan melakukan join data untuk mendapatkan nama terbaru
      final futures = snap.docs.map((doc) async {
        final anggotaData = doc.data();
        final uidSiswa = doc.id;
  
        // Ambil profil siswa terbaru
        final siswaDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('siswa').doc(uidSiswa).get();
        
        // Dapatkan nama dari field peranKomite sebagai prioritas utama
        final peranKomite = siswaDoc.data()?['peranKomite'] as Map<String, dynamic>?;
        final namaOrangTuaTerkini = peranKomite?['namaOrangTua'] ?? anggotaData['namaOrangTua'] ?? 'Nama Belum Diatur';
  
        return KomiteAnggotaModel(
          uidSiswa: uidSiswa,
          namaSiswa: anggotaData['namaSiswa'],
          namaOrangTua: namaOrangTuaTerkini, // Gunakan nama terkini
          jabatan: anggotaData['jabatan'],
          komiteId: 'sekolah',
        );
      }).toList();
  
      anggotaKomiteSekolah.assignAll(await Future.wait(futures));
      // [PERBAIKAN SELESAI]
  
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data komite: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> tambahAnggota() async {
    final SiswaSelectionModel? siswaTerpilih = await _showSiswaSearchDialog();
    if (siswaTerpilih == null) return;

    final String? jabatan = await _showJabatanInputDialog();
    if (jabatan == null || jabatan.isEmpty) return;

    isProcessing.value = true;
    try {
      final taAktif = configC.tahunAjaranAktif.value;
      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswaTerpilih.uid);
      final anggotaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('komite').doc('sekolah')
          .collection('anggota').doc(siswaTerpilih.uid);
      
      final WriteBatch batch = _firestore.batch();

      batch.set(anggotaRef, {
        'namaSiswa': siswaTerpilih.nama,
        'namaOrangTua': siswaTerpilih.namaOrangTua ?? 'Wali ${siswaTerpilih.nama}',
        'jabatan': jabatan,
        'timestamp': FieldValue.serverTimestamp(),
      });

      batch.update(siswaRef, {
        'peranKomite': {
          'jabatan': jabatan,
          'namaOrangTua': siswaTerpilih.namaOrangTua ?? 'Wali ${siswaTerpilih.nama}',
        }
      });

      await batch.commit();
      Get.snackbar("Berhasil", "${siswaTerpilih.nama} telah ditambahkan sebagai $jabatan.");
      await fetchData();
    } catch (e) {
      Get.snackbar("Error", "Gagal menambah anggota: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> hapusAnggota(KomiteAnggotaModel anggota) async {
    isProcessing.value = true;
    try {
      final taAktif = configC.tahunAjaranAktif.value;
      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(anggota.uidSiswa);
      final anggotaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('komite').doc('sekolah')
          .collection('anggota').doc(anggota.uidSiswa);

      final WriteBatch batch = _firestore.batch();
      batch.delete(anggotaRef);
      batch.update(siswaRef, {'peranKomite': FieldValue.delete()});
      await batch.commit();
      Get.snackbar("Berhasil", "${anggota.namaSiswa} telah dihapus dari jabatannya.");
      await fetchData();
    } catch (e) {
      Get.snackbar("Error", "Gagal menghapus anggota: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }
  
  Future<String?> _showJabatanInputDialog() async {
    // [PERBAIKAN] Gunakan Dropdown dengan daftar jabatan hardcoded
    final List<String> daftarJabatan = [
      'Bendahara Komite Sekolah',
      'Sekretaris Komite Sekolah',
      'Anggota Divisi Pendidikan',
      'Anggota Divisi Humas',
      'Anggota' // Opsi fallback
    ];
    final RxString jabatanTerpilih = daftarJabatan.first.obs;

    final result = await Get.dialog(
      AlertDialog(
        title: const Text("Pilih Jabatan Anggota"),
        content: Obx(() => DropdownButton<String>(
          value: jabatanTerpilih.value,
          isExpanded: true,
          items: daftarJabatan.map((String jabatan) {
            return DropdownMenuItem<String>(
              value: jabatan,
              child: Text(jabatan),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              jabatanTerpilih.value = newValue;
            }
          },
        )),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () => Get.back(result: jabatanTerpilih.value),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
    return result;
  }
  
  void _filterSiswaDialog() {
    final query = searchC.text.toLowerCase();
    if (query.isEmpty) {
      hasilPencarian.assignAll(_daftarSiswaMaster);
    } else {
      hasilPencarian.assignAll(_daftarSiswaMaster.where((siswa) {
        return siswa.nama.toLowerCase().contains(query);
      }));
    }
  }

  Future<SiswaSelectionModel?> _showSiswaSearchDialog() async {
    searchC.clear();
    hasilPencarian.assignAll(_daftarSiswaMaster);
    searchC.addListener(_filterSiswaDialog);
    final SiswaSelectionModel? result = await Get.dialog(
      AlertDialog(
        title: const Text("Cari & Pilih Siswa"),
        content: SizedBox(
          width: Get.width * 0.9,
          height: Get.height * 0.6,
          child: Column(
            children: [
              TextField(
                controller: searchC,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Ketik nama siswa...",
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  if (hasilPencarian.isEmpty) {
                    return const Center(child: Text("Siswa tidak ditemukan."));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: hasilPencarian.length,
                    itemBuilder: (context, index) {
                      final siswa = hasilPencarian[index];
                      return ListTile(
                        title: Text(siswa.nama),
                        subtitle: Text("Kelas: ${siswa.kelasId.split('-').first}"),
                        onTap: () => Get.back(result: siswa),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
    searchC.removeListener(_filterSiswaDialog);
    return result;
  }

  @override
  void onClose() {
    searchC.dispose();
    super.onClose();
  }
}