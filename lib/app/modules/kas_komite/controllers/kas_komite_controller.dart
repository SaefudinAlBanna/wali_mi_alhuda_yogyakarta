// lib/app/modules/kas_komite/controllers/kas_komite_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controllers/account_manager_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/komite_log_transaksi_model.dart';
import '../../../models/komite_transfer_model.dart';
import '../../../services/notifikasi_komite_service.dart';

class KasKomiteController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AccountManagerController accountManagerC = Get.find<AccountManagerController>();

  final isLoading = true.obs;
  final isProcessing = false.obs;
  
  // Peran Pengguna
  final isBendaharaKelas = false.obs;
  final isBendaharaSekolah = false.obs;
  final isKetuaSekolah = false.obs; // [BARU]

  final RxList<KomiteLogTransaksiModel> daftarTransaksi = <KomiteLogTransaksiModel>[].obs;
  final RxList<KomiteTransferModel> daftarTransferPending = <KomiteTransferModel>[].obs;
  final RxInt saldoKas = 0.obs;
  String komiteId = '';
  String get taAktif => configC.tahunAjaranAktif.value;

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  Future<void> initialize() async {
    isLoading.value = true;
    _determineRoleAndKomiteId();
    if (komiteId.isNotEmpty) {
      await Future.wait([
        fetchLogTransaksi(),
        if (isBendaharaSekolah.value) fetchPendingTransfers(),
      ]);
    }
    isLoading.value = false;
  }

  void _determineRoleAndKomiteId() {
    final peran = accountManagerC.currentActiveStudent.value?.peranKomite?['jabatan'];
    if (peran == 'Bendahara Kelas') {
      isBendaharaKelas.value = true;
      final kelasId = accountManagerC.currentActiveStudent.value?.kelasId;
      if (kelasId != null) komiteId = kelasId.split('-').first;
    } else if (peran == 'Bendahara Komite Sekolah') {
      isBendaharaSekolah.value = true;
      komiteId = 'sekolah';
    } else if (peran == 'Ketua Komite Sekolah') { // [BARU]
      isKetuaSekolah.value = true;
      komiteId = 'sekolah';
    }
  }

  Future<void> fetchLogTransaksi() async {
    if (komiteId.isEmpty) return;
    try {
      final snap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(taAktif)
        .collection('komite').doc(komiteId)
        .collection('log_transaksi').orderBy('timestamp', descending: true).get();
      daftarTransaksi.assignAll(snap.docs.map((d) => KomiteLogTransaksiModel.fromFirestore(d)).toList());
      _hitungSaldo();
    } catch(e) {
      Get.snackbar("Error", "Gagal memuat log transaksi: ${e.toString()}");
    }
  }

  void _hitungSaldo() {
    int saldo = 0;
    for (var trx in daftarTransaksi) {
      if (trx.jenis == 'Pemasukan' || trx.jenis == 'MASUK') {
        saldo += trx.nominal;
      } else if (trx.jenis == 'Pengeluaran' || trx.jenis == 'KELUAR') { // [PERBAIKAN] Tambahkan 'KELUAR'
        // Hanya kurangi saldo jika pengeluaran disetujui, atau jika itu adalah transfer keluar
        if (trx.status == 'disetujui' || trx.jenis == 'KELUAR') {
          saldo -= trx.nominal;
        }
      }
    }
    saldoKas.value = saldo;
  }

  // --- FUNGSI-FUNGSI BARU UNTUK MISI 7C ---

  // Bendahara: Catat Pemasukan
  Future<void> catatPemasukanLain(String sumber, int nominal, String keterangan) async {
    isProcessing.value = true;
    try {
      final user = accountManagerC.currentActiveStudent.value!;
      await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(taAktif)
        .collection('komite').doc('sekolah').collection('log_transaksi').add({
          'jenis': 'Pemasukan',
          'sumber': sumber,
          'deskripsi': keterangan,
          'nominal': nominal,
          'timestamp': FieldValue.serverTimestamp(),
          'pencatatId': user.uid,
          'pencatatNama': user.peranKomite?['namaOrangTua'] ?? 'Wali ${user.namaLengkap}',
        });
      Get.snackbar("Berhasil", "Pemasukan berhasil dicatat.", backgroundColor: Colors.green, colorText: Colors.white);
      await fetchLogTransaksi();
    } catch (e) {
      Get.snackbar("Error", "Gagal mencatat pemasukan: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }

  // Bendahara: Ajukan Pengeluaran
  Future<void> ajukanPengeluaran(String tujuan, int nominal, String keterangan) async {
    // [PERBAIKAN KUNCI DI SINI] Tambahkan blok validasi di awal
    if (nominal > saldoKas.value) {
      Get.snackbar(
        "Saldo Tidak Cukup",
        "Pengajuan sebesar ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(nominal)} melebihi saldo kas saat ini (${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(saldoKas.value)}).",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM
      );
      return; // Hentikan eksekusi jika saldo tidak cukup
    } 

    isProcessing.value = true;
    try {
      final user = accountManagerC.currentActiveStudent.value!;
      await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(taAktif)
        .collection('komite').doc('sekolah').collection('log_transaksi').add({
          'jenis': 'Pengeluaran',
          'tujuan': tujuan,
          'deskripsi': keterangan,
          'nominal': nominal,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
          'pengajuId': user.uid,
          'pengajuNama': user.peranKomite?['namaOrangTua'] ?? 'Wali ${user.namaLengkap}',
        });
        // [INTEGRASI NOTIFIKASI 1] Kirim notifikasi ke Ketua Komite
        final ketuaRef = await _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('tahunajaran').doc(taAktif)
            .collection('komite').doc('sekolah').collection('anggota')
            .where('jabatan', isEqualTo: 'Ketua Komite Sekolah').limit(1).get();
            
        if (ketuaRef.docs.isNotEmpty) {
          final uidKetua = ketuaRef.docs.first.id;
          await NotifikasiKomiteService.kirimNotifikasi(
            uidPenerima: uidKetua,
            judul: "Persetujuan Diperlukan",
            isi: "Ada pengajuan pengeluaran baru dari Bendahara Komite sebesar ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(nominal)}.",
          );
        }   

        Get.snackbar("Berhasil", "Pengajuan pengeluaran telah dikirim untuk persetujuan.");
        await fetchLogTransaksi();
      } catch (e) {
        Get.snackbar("Error", "Gagal mengajukan pengeluaran: ${e.toString()}");
      } finally {
        isProcessing.value = false;
      }
    }

  // Ketua: Setujui Pengeluaran
  Future<void> setujuiPengeluaran(String logId) async {
    isProcessing.value = true;
    try {
      final user = accountManagerC.currentActiveStudent.value!;
      final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('komite').doc('sekolah').collection('log_transaksi').doc(logId);

      final docSnap = await docRef.get();
      if (!docSnap.exists) throw Exception("Dokumen pengajuan tidak ditemukan!");
      final pengajuId = docSnap.data()?['pengajuId'];

      final ketuaProfilDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(user.uid).get();
      final peranKomiteKetua = ketuaProfilDoc.data()?['peranKomite'] as Map<String, dynamic>?;
      final namaKetuaTerkini = peranKomiteKetua?['namaOrangTua'] ?? 'Wali ${user.namaLengkap}';

      await docRef.update({
        'status': 'disetujui',
        'penyetujuId': user.uid,
        'penyetujuNama': namaKetuaTerkini,
        'waktuPersetujuan': FieldValue.serverTimestamp(),
      });

      if (pengajuId != null) {
        await NotifikasiKomiteService.kirimNotifikasi(
          uidPenerima: pengajuId,
          judul: "Pengajuan Disetujui",
          isi: "Pengajuan pengeluaran Anda untuk '${docSnap.data()?['tujuan']}' telah disetujui oleh Ketua Komite.",
        );
      }

      await fetchLogTransaksi();
    } catch (e) {
      Get.snackbar("Error", "Gagal menyetujui pengeluaran: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }
  
  // Ketua: Tolak Pengeluaran
  Future<void> tolakPengeluaran(String logId, String alasan) async {
    isProcessing.value = true;
    try {
      final user = accountManagerC.currentActiveStudent.value!;
      final docRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('komite').doc('sekolah').collection('log_transaksi').doc(logId);  

      final docSnap = await docRef.get();
      if (!docSnap.exists) throw Exception("Dokumen pengajuan tidak ditemukan!");
      final pengajuId = docSnap.data()?['pengajuId']; 

      final ketuaProfilDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(user.uid).get();
      final peranKomiteKetua = ketuaProfilDoc.data()?['peranKomite'] as Map<String, dynamic>?;
      final namaKetuaTerkini = peranKomiteKetua?['namaOrangTua'] ?? 'Wali ${user.namaLengkap}';
      
      await docRef.update({
        'status': 'ditolak',
        'alasanPenolakan': alasan,
        'penyetujuId': user.uid,
        'penyetujuNama': namaKetuaTerkini,
        'waktuPersetujuan': FieldValue.serverTimestamp(),
      }); 

      if (pengajuId != null) {
        await NotifikasiKomiteService.kirimNotifikasi(
          uidPenerima: pengajuId,
          judul: "Pengajuan Ditolak",
          isi: "Pengajuan pengeluaran Anda untuk '${docSnap.data()?['tujuan']}' ditolak. Alasan: $alasan",
        );
      } 

      await fetchLogTransaksi();
    } catch (e) {
      Get.snackbar("Error", "Gagal menolak pengeluaran: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }

  // --- Sisa fungsi lama yang masih relevan ---
  Future<void> fetchPendingTransfers() async {
    try {
      final snap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(taAktif)
        .collection('komite_transfers').where('status', isEqualTo: 'pending').get();
      daftarTransferPending.assignAll(snap.docs.map((d) => KomiteTransferModel.fromFirestore(d)).toList());
    } catch(e) {
      Get.snackbar("Error", "Gagal memuat data setoran pending: ${e.toString()}");
    }
  }

  void showDialogSetorDana() {
    final nominalC = TextEditingController();
    final catatanC = TextEditingController();
    final formKey = GlobalKey<FormState>();
  
    Get.defaultDialog(
      title: "Setor Dana ke Komite Sekolah",
      content: Form(
        key: formKey,
        child: Column(
          children: [
            // [PERBAIKAN] Tampilkan saldo dengan format yang lebih baik
            Text("Saldo kas kelas saat ini: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(saldoKas.value)}"),
            const SizedBox(height: 16),
            TextFormField(
              controller: nominalC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Nominal Disetor", prefixText: "Rp "),
              validator: (value) {
                if (value == null || value.isEmpty) return "Wajib diisi";
                final nominal = int.tryParse(value);
                if (nominal == null) return "Masukkan angka yang valid";
                if (nominal <= 0) return "Nominal harus lebih dari nol";
                // [PERBAIKAN] Pesan validasi yang lebih informatif
                if (nominal > saldoKas.value) {
                  return "Nominal melebihi saldo kas yang tersedia!";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: catatanC,
              decoration: const InputDecoration(labelText: "Catatan (Opsional)"),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: isProcessing.value ? null : () {
          if (formKey.currentState!.validate()) {
            Get.back();
            _prosesSetorDana(int.parse(nominalC.text), catatanC.text);
          }
        },
        child: isProcessing.value ? const CircularProgressIndicator(color: Colors.white) : const Text("Ajukan Setoran"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }


  Future<void> _prosesSetorDana(int nominal, String catatan) async {
    isProcessing.value = true;
    try {
      final user = accountManagerC.currentActiveStudent.value!;
      await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(taAktif)
        .collection('komite_transfers').add({
          'dariKomiteId': komiteId,
          'keKomiteId': 'sekolah',
          'nominal': nominal,
          'catatan': catatan,
          'status': 'pending',
          'diajukanOlehUid': user.uid,
          'diajukanOlehNama': user.peranKomite?['namaOrangTua'] ?? 'Wali ${user.namaLengkap}',
          'tanggalAjuan': FieldValue.serverTimestamp(),
          'diterimaOlehUid': null,
          'diterimaOlehNama': null,
          'tanggalDiterima': null,
        });
        final bendaharaRef = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(taAktif)
        .collection('komite').doc('sekolah').collection('anggota')
        .where('jabatan', isEqualTo: 'Bendahara Komite Sekolah').limit(1).get();

    if (bendaharaRef.docs.isNotEmpty) {
      final uidBendahara = bendaharaRef.docs.first.id;
      await NotifikasiKomiteService.kirimNotifikasi(
        uidPenerima: uidBendahara,
        judul: "Setoran Dana Masuk",
        isi: "Ada setoran dana dari Komite Kelas $komiteId sebesar ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(nominal)} yang menunggu konfirmasi Anda.",
      );
    }

    Get.snackbar("Berhasil", "Pengajuan setor dana telah terkirim.");
    } catch (e) {
      Get.snackbar("Error", "Gagal mengajukan setoran: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }
  
  Future<void> terimaDana(KomiteTransferModel transfer) async {
    isProcessing.value = true;
    try {
      final user = accountManagerC.currentActiveStudent.value!;
      final batch = _firestore.batch();

      final bendaharaProfilDoc = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').doc(user.uid).get();
      final peranKomiteBendahara = bendaharaProfilDoc.data()?['peranKomite'] as Map<String, dynamic>?;
      final namaBendaharaTerkini = peranKomiteBendahara?['namaOrangTua'] ?? 'Wali ${user.namaLengkap}';

      final transferRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('komite_transfers').doc(transfer.id);

      final logKeluarRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('komite').doc(transfer.dariKomiteId)
          .collection('log_transaksi').doc();

      final logMasukRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif)
          .collection('komite').doc('sekolah')
          .collection('log_transaksi').doc();

      batch.update(transferRef, {
        'status': 'completed',
        'diterimaOlehUid': user.uid,
        'diterimaOlehNama': namaBendaharaTerkini,
        'tanggalDiterima': FieldValue.serverTimestamp(),
      });

      batch.set(logKeluarRef, {
        'jenis': 'KELUAR',
        'deskripsi': 'Setor dana ke Komite Sekolah',
        'nominal': transfer.nominal,
        'timestamp': FieldValue.serverTimestamp(),
        'ref_transferId': transfer.id,
      });

      batch.set(logMasukRef, {
        'jenis': 'MASUK',
        'deskripsi': 'Terima setoran dari Komite Kelas ${transfer.dariKomiteId}',
        'nominal': transfer.nominal,
        'timestamp': FieldValue.serverTimestamp(),
        'ref_transferId': transfer.id,
      });

      await batch.commit();

      // [INTEGRASI NOTIFIKASI 4] Kirim notifikasi ke Bendahara Kelas
      await NotifikasiKomiteService.kirimNotifikasi(
        uidPenerima: transfer.diajukanOlehUid, // Sekarang sudah valid
        judul: "Setoran Diterima",
        isi: "Setoran dana sebesar ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(transfer.nominal)} dari kelas Anda telah diterima oleh Bendahara Komite Sekolah.",
      );

      Get.snackbar("Berhasil", "Setoran dana telah diterima.");
      await initialize();
    } catch (e) {
      Get.snackbar("Error", "Gagal menerima dana: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }
}