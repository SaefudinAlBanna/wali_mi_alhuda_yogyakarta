// lib/app/modules/manajemen_iuran/controllers/manajemen_iuran_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controllers/account_manager_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/iuran_komite_model.dart';
import '../../../models/siswa_iuran_status_model.dart';
import '../../../models/siswa_selection_model.dart';

class ManajemenIuranController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AccountManagerController accountManagerC = Get.find<AccountManagerController>();

  final isLoading = true.obs;
  final isProcessing = false.obs;
  final isAuthorized = false.obs;

  final RxList<SiswaIuranStatus> daftarSiswaDenganStatus = <SiswaIuranStatus>[].obs;
  final Rx<DateTime> bulanTerpilih = DateTime.now().obs;
  final nominalWajibC = TextEditingController(text: "5000");

  @override
  void onInit() {
    super.onInit();
    ever(bulanTerpilih, (_) => _checkAuthorizationAndFetchData());
    _checkAuthorizationAndFetchData();
  }

  Future<void> _checkAuthorizationAndFetchData() async {
    isLoading.value = true;
    final peranKomite = accountManagerC.currentActiveStudent.value?.peranKomite;
    if (peranKomite != null && peranKomite['jabatan'] == 'Bendahara Kelas') {
      isAuthorized.value = true;
      await _fetchDataSiswaDanIuran();
    } else {
      isAuthorized.value = false;
    }
    isLoading.value = false;
  }

  Future<void> _fetchDataSiswaDanIuran() async {
    try {
      final kelasId = accountManagerC.currentActiveStudent.value?.kelasId;
      if (kelasId == null) throw Exception("ID Kelas tidak ditemukan.");
      
      final taAktif = configC.tahunAjaranAktif.value;
      final bulanId = DateFormat('yyyy-MM').format(bulanTerpilih.value);

      final daftarSiswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('kelastahunajaran').doc(kelasId)
          .collection('daftarsiswa');
      
      final siswaSnap = await daftarSiswaRef.get();
      
      final List<SiswaSelectionModel> siswaDiKelas = siswaSnap.docs.map((d) {
        final data = d.data();
        return SiswaSelectionModel(
          uid: d.id,
          nama: data['namaLengkap'] ?? 'Tanpa Nama',
          kelasId: data['kelasId'] ?? 'N/A',
        );
      }).toList();

      if (siswaDiKelas.isEmpty) {
        daftarSiswaDenganStatus.clear();
        return;
      }
      
      final Map<String, IuranKomiteModel> mapIuran = {};
      for (var siswa in siswaDiKelas) {
        final iuranDoc = await daftarSiswaRef.doc(siswa.uid).collection('iuran_komite').doc(bulanId).get();
        if (iuranDoc.exists) {
          mapIuran[siswa.uid] = IuranKomiteModel.fromFirestore(iuranDoc);
        }
      }

      final List<SiswaIuranStatus> siswaListFinal = siswaDiKelas.map((siswa) {
        return SiswaIuranStatus(
          uid: siswa.uid,
          namaLengkap: siswa.nama,
          iuranBulanIni: mapIuran[siswa.uid],
        );
      }).toList();
      
      siswaListFinal.sort((a,b) => a.namaLengkap.compareTo(b.namaLengkap));
      daftarSiswaDenganStatus.assignAll(siswaListFinal);

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data: ${e.toString()}");
      print("### ERROR FETCH IURAN: $e");
    }
  }
  
  void gantiBulan(int increment) {
    bulanTerpilih.value = DateTime(
      bulanTerpilih.value.year,
      bulanTerpilih.value.month + increment,
      1
    );
  }

  Future<void> showPembayaranDialog(SiswaIuranStatus siswa) async {
    final nominalBayarC = TextEditingController();
    nominalBayarC.text = nominalWajibC.text;

    await Get.defaultDialog(
      title: "Catat Iuran: ${siswa.namaLengkap}",
      content: Column(
        children: [
          Text("Iuran wajib bulan ${DateFormat.MMMM('id_ID').format(bulanTerpilih.value)} adalah Rp ${nominalWajibC.text}"),
          const SizedBox(height: 16),
          TextField(
            controller: nominalBayarC,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Nominal Dibayar",
              prefixText: "Rp ",
              border: OutlineInputBorder(),
            ),
          )
        ],
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: isProcessing.value ? null : () {
          // [PERBAIKAN] Kirim juga nama siswa untuk deskripsi log
          _validateAndSave(siswa.uid, siswa.namaLengkap, nominalBayarC.text);
        },
        child: isProcessing.value 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
          : const Text("Simpan"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  // [PERBAIKAN] Tambahkan parameter namaSiswa
  void _validateAndSave(String uidSiswa, String namaSiswa, String nominalBayarString) {
      final nominalBayar = int.tryParse(nominalBayarString) ?? 0;
      final nominalWajib = int.tryParse(nominalWajibC.text) ?? 0;

      if (nominalBayar < nominalWajib) {
        Get.snackbar(
          "Pembayaran Kurang", 
          "Nominal yang dibayar tidak boleh kurang dari iuran wajib (Rp $nominalWajib).",
          backgroundColor: Colors.red,
          colorText: Colors.white
        );
        return;
      }
      
      Get.back();
      // [PERBAIKAN] Kirim juga nama siswa ke fungsi simpan
      _simpanPembayaran(uidSiswa, namaSiswa, nominalBayar);
  }
  
  // [PERBAIKAN] Tambahkan parameter namaSiswa dan gunakan WriteBatch
  Future<void> _simpanPembayaran(String uidSiswa, String namaSiswa, int nominalBayar) async {
    isProcessing.value = true;
    try {
      final kelasId = accountManagerC.currentActiveStudent.value?.kelasId;
      final pencatat = accountManagerC.currentActiveStudent.value;
      if (kelasId == null || pencatat == null) {
        throw Exception("Data pengguna tidak lengkap.");
      }

      final taAktif = configC.tahunAjaranAktif.value;
      final bulanId = DateFormat('yyyy-MM').format(bulanTerpilih.value);
      final namaBulan = DateFormat('MMMM', 'id_ID').format(bulanTerpilih.value);
      final komiteId = kelasId.split('-').first;
      final nominalWajib = int.tryParse(nominalWajibC.text) ?? 0;

      final iuranRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('kelastahunajaran').doc(kelasId)
          .collection('daftarsiswa').doc(uidSiswa)
          .collection('iuran_komite').doc(bulanId);

      final logRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('komite').doc(komiteId)
          .collection('log_transaksi').doc();

      final batch = _firestore.batch();

      batch.set(iuranRef, {
        'id': bulanId,
        'bulan': bulanTerpilih.value.month,
        'tahun': bulanTerpilih.value.year,
        'nominalWajib': nominalWajib,
        'nominalBayar': nominalBayar,
        'tanggalBayar': Timestamp.now(),
        'status': 'Lunas',
        'dicatatOlehUid': pencatat.uid,
        'dicatatOlehNama': pencatat.peranKomite?['namaOrangTua'] ?? 'Wali ${pencatat.namaLengkap}',
        'idTahunAjaran': taAktif,
        'kelasId': kelasId,
        'uidSiswa': uidSiswa,
      });

      batch.set(logRef, {
        'jenis': 'MASUK',
        'deskripsi': 'Iuran Komite bulan $namaBulan dari $namaSiswa',
        'nominal': nominalBayar,
        // [PERBAIKAN KUNCI DI SINI]
        'timestamp': FieldValue.serverTimestamp(), // 'tanggal' -> 'timestamp'
        'ref_iuranId': iuranRef.path,
      });

      await batch.commit();

      Get.snackbar("Berhasil", "Pembayaran iuran berhasil dicatat.", backgroundColor: Colors.green, colorText: Colors.white);
      await _fetchDataSiswaDanIuran();

    } catch(e) {
      Get.snackbar("Error", "Gagal mencatat pembayaran: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }

  @override
  void onClose() {
    nominalWajibC.dispose();
    super.onClose();
  }
}