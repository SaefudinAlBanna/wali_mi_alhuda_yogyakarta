import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/siswa_keuangan_model.dart';
import '../../../models/tagihan_model.dart';
import '../../../models/transaksi_model.dart';

class DetailKeuanganSiswaController extends GetxController with GetTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>();

  late TabController tabController;
  final isLoading = true.obs;

  final RxList<TagihanModel> tagihanSPP = <TagihanModel>[].obs;
  final RxList<TagihanModel> tagihanLainnya = <TagihanModel>[].obs;
  final RxList<TransaksiModel> riwayatTransaksi = <TransaksiModel>[].obs;
  final Rxn<TagihanModel> tagihanUangPangkal = Rxn<TagihanModel>();
  final RxInt totalTunggakan = 0.obs; // [BARU] Tambahkan properti ini
  
  final RxList<String> tabTitles = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 0, vsync: this);
    _loadDataKeuangan();
  }

  Future<void> _loadDataKeuangan() async {
    isLoading.value = true;
    try {
      final uidSiswa = authC.auth.currentUser!.uid;
      final taAktif = configC.tahunAjaranAktif.value;

      final tahun = int.parse(taAktif.split('-').first);
      final taLama = "${tahun - 1}-${tahun}";

      final keuanganAktifRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taAktif).collection('keuangan_siswa').doc(uidSiswa);
      final keuanganLamaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(taLama).collection('keuangan_siswa').doc(uidSiswa);
      final tagihanPangkalRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('keuangan_sekolah').doc('tagihan_uang_pangkal').collection('tagihan').doc(uidSiswa);

      // [MODIFIKASI 1] Tambahkan referensi ke koleksi tunggakan awal
      final tunggakanAwalRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tunggakanAwal').doc(uidSiswa);

      final results = await Future.wait([
        keuanganAktifRef.collection('tagihan').get(),
        keuanganAktifRef.collection('transaksi').orderBy('tanggalBayar', descending: true).get(),
        tagihanPangkalRef.get(),
        keuanganLamaRef.collection('tagihan').where('status', isNotEqualTo: 'Lunas').get(),

        // [MODIFIKASI 2] Tambahkan get() untuk tunggakan awal ke dalam Future.wait
        tunggakanAwalRef.get(),
      ]);

      _prosesDataTagihan(
        results[0] as QuerySnapshot<Map<String, dynamic>>,
        results[2] as DocumentSnapshot<Map<String, dynamic>>,
        results[3] as QuerySnapshot<Map<String, dynamic>>,

        // [MODIFIKASI 3] Kirim hasil snapshot tunggakan awal ke fungsi pemrosesan
        results[4] as DocumentSnapshot<Map<String, dynamic>>,
      );
      _prosesDataTransaksi(results[1] as QuerySnapshot<Map<String, dynamic>>);
      _buatTabDinamis();
      _hitungTotalTunggakan();

    } catch(e) {
      Get.snackbar("Error", "Gagal memuat data keuangan: ${e.toString()}");
      print("### Error Keuangan Orang Tua: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _hitungTotalTunggakan() {
    int total = 0;
    final semuaTagihan = [...tagihanSPP, ...tagihanLainnya];
    if (tagihanUangPangkal.value != null) {
      semuaTagihan.add(tagihanUangPangkal.value!);
    }
    
    final now = DateTime.now();
    for (var tagihan in semuaTagihan) {
      if (tagihan.status != 'Lunas') {
        bool isDue = true;
        if (tagihan.jenisPembayaran == 'SPP') {
          if (tagihan.tanggalJatuhTempo != null && tagihan.tanggalJatuhTempo!.toDate().isAfter(now)) {
            isDue = false;
          }
        }
        if (isDue) {
          total += tagihan.sisaTagihan;
        }
      }
    }
    totalTunggakan.value = total;
  }

  void _prosesDataTagihan(
      QuerySnapshot<Map<String, dynamic>> snapTahunan,
      DocumentSnapshot<Map<String, dynamic>> snapPangkal,
      QuerySnapshot<Map<String, dynamic>> snapTunggakanLama,
      // [MODIFIKASI 4] Tambahkan parameter baru
      DocumentSnapshot<Map<String, dynamic>> snapTunggakanAwal) {
        
    tagihanSPP.clear();
    tagihanLainnya.clear();
    tagihanUangPangkal.value = null;
  
    // [MODIFIKASI 5] Proses data tunggakan awal jika ada (Logika sama persis dengan Aplikasi Sekolah)
    if (snapTunggakanAwal.exists && (snapTunggakanAwal.data()?['lunas'] ?? false) == false) {
      final data = snapTunggakanAwal.data()!;
      final sisa = (data['sisaTunggakan'] as num?)?.toInt() ?? 0;
  
      if (sisa > 0) {
        final tagihanAwal = TagihanModel(
          id: "TUNGGAKAN-AWAL-${snapTunggakanAwal.id}",
          deskripsi: data['keterangan'] ?? "Tunggakan awal sistem",
          jenisPembayaran: "Tunggakan Lama", // Kelompokkan agar mudah dilihat
          jumlahTagihan: (data['totalTunggakan'] as num?)?.toInt() ?? 0,
          jumlahTerbayar: ((data['totalTunggakan'] as num?)?.toInt() ?? 0) - sisa,
          status: 'Jatuh Tempo',
          isTunggakan: true,
          metadata: {'sumber': 'tunggakanAwal'},
        );
        tagihanLainnya.add(tagihanAwal);
      }
    }
  
    // Sisa fungsi tidak berubah, hanya menyalin logika yang sudah ada
    for (var doc in snapTunggakanLama.docs) {
      final tagihan = TagihanModel.fromFirestore(doc);
      final tagihanTunggakan = TagihanModel(
        id: "TUNGGAKAN-${tagihan.id}",
        deskripsi: "Tunggakan ${tagihan.deskripsi}",
        isTunggakan: true,
        jenisPembayaran: tagihan.jenisPembayaran,
        jumlahTagihan: tagihan.sisaTagihan,
        jumlahTerbayar: 0,
        status: 'Jatuh Tempo',
        tanggalJatuhTempo: tagihan.tanggalJatuhTempo,
        metadata: tagihan.metadata,
        kelasSaatDitagih: tagihan.kelasSaatDitagih,
      );
      if (tagihanTunggakan.jenisPembayaran == 'SPP') tagihanSPP.add(tagihanTunggakan);
      else tagihanLainnya.add(tagihanTunggakan);
    }
  
    for (var doc in snapTahunan.docs) {
      final tagihan = TagihanModel.fromFirestore(doc);
      if (tagihan.jenisPembayaran == 'SPP') tagihanSPP.add(tagihan);
      else tagihanLainnya.add(tagihan);
    }
  
    tagihanSPP.sort((a, b) {
      if (a.isTunggakan && !b.isTunggakan) return -1;
      if (!a.isTunggakan && b.isTunggakan) return 1;
      return a.tanggalJatuhTempo!.compareTo(b.tanggalJatuhTempo!);
    });
  
    if (snapPangkal.exists) {
      tagihanUangPangkal.value = TagihanModel.fromFirestore(snapPangkal);
    }
  }

  void _prosesDataTransaksi(QuerySnapshot<Map<String, dynamic>> snapshot) {
    riwayatTransaksi.assignAll(snapshot.docs.map((doc) => TransaksiModel.fromFirestore(doc)).toList());
  }

  void _buatTabDinamis() {
    final Set<String> jenisTagihan = {};
    if (tagihanUangPangkal.value != null) jenisTagihan.add("Uang Pangkal");
    if (tagihanSPP.isNotEmpty) jenisTagihan.add("SPP");
    for (var tagihan in tagihanLainnya) {
      jenisTagihan.add(tagihan.jenisPembayaran);
    }
    
    final titles = jenisTagihan.toList()..sort();
    if (riwayatTransaksi.isNotEmpty) {
      titles.add("Riwayat");
    }
    
    tabTitles.assignAll(titles);
    if (titles.isNotEmpty) {
      tabController = TabController(length: tabTitles.length, vsync: this);
    }
  }

  void showDetailTunggakan() {
    final List<TagihanModel> daftarTunggakan = [];
    final semuaTagihan = [...tagihanSPP, ...tagihanLainnya];
    if (tagihanUangPangkal.value != null) {
      semuaTagihan.add(tagihanUangPangkal.value!);
    }

    final now = DateTime.now();

    for (var tagihan in semuaTagihan) {
      if (tagihan.status != 'Lunas') {
        bool isTunggakan = true; 

        // Logika khusus untuk SPP: hanya tampilkan jika sudah jatuh tempo
        if (tagihan.jenisPembayaran == 'SPP') {
          if (tagihan.tanggalJatuhTempo == null || tagihan.tanggalJatuhTempo!.toDate().isAfter(now)) {
            isTunggakan = false;
          }
        }

        if (isTunggakan) {
          daftarTunggakan.add(tagihan);
        }
      }
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Detail Tunggakan", style: Get.textTheme.titleLarge),
            const Divider(),
            _buildDetailRowDialog("Nama Siswa", configC.infoUser['namaLengkap'] ?? ''),
            _buildDetailRowDialog("Kelas", configC.infoUser['kelasId']?.split('-').first ?? "N/A"),
            const SizedBox(height: 16),

            Text("Rincian:", style: Get.textTheme.titleMedium),
            const SizedBox(height: 8),

            Flexible(
              child: daftarTunggakan.isEmpty
                  ? const Text("Tidak ada tunggakan saat ini.")
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: daftarTunggakan.length,
                      itemBuilder: (context, index) {
                        final tunggakan = daftarTunggakan[index];
                        return ListTile(
                          dense: true,
                          title: Text(tunggakan.deskripsi),
                          trailing: Text(
                            "Rp ${NumberFormat.decimalPattern('id_ID').format(tunggakan.sisaTagihan)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // [FUNGSI BARU] Tambahkan fungsi ini (sama seperti di aplikasi sekolah)
  void showDetailTransaksiDialog(TransaksiModel trx) {
    Get.defaultDialog(
      title: "Rincian Transaksi",
      titlePadding: const EdgeInsets.all(20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRowDialog("Jumlah Bayar", "Rp ${NumberFormat.decimalPattern('id_ID').format(trx.jumlahBayar)}"),
          _buildDetailRowDialog("Tanggal", DateFormat('EEEE, dd MMM yyyy, HH:mm', 'id_ID').format(trx.tanggalBayar)),
          _buildDetailRowDialog("Metode", trx.metodePembayaran),
          _buildDetailRowDialog("Pencatat", trx.dicatatOlehNama),
          const Divider(height: 24),
          const Text("Keterangan/Alokasi:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(trx.keterangan.isNotEmpty ? trx.keterangan : "Tidak ada keterangan."),
        ],
      ),
      confirm: TextButton(onPressed: Get.back, child: const Text("Tutup")),
    );
  }

  // [WIDGET BANTUAN BARU] Tambahkan widget helper ini (sama seperti di aplikasi sekolah)
  Widget _buildDetailRowDialog(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(width: 16),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}