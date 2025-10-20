import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/pembayaran_model.dart';

class DaftarSppController extends GetxController with StateMixin {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final String idSekolah = "P9984539";

  // Data UI
  var sppPerBulan = 0.obs;
  var totalKekuranganSpp = 0.obs;
  var bulanSudahBayar = 0.obs;
  var daftarBulanSpp = <BulanSppModel>[].obs;
  var daftarPembayaranLain = <PembayaranLainModel>[].obs;

  // Data Internal
  late String nisn;
  late String idKelas;
  late String tahunAjaran;

  final List<String> bulanTahunAjaran = [
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni'
  ];
  final List<String> jenisPembayaranLain = [
    'Daftar Ulang', 'Iuran Pangkal', 'Kegiatan', 'Seragam', 'UPK ASPD'
  ];

  @override
  void onInit() {
    super.onInit();
    fetchSemuaDataPembayaran();
  }

  Future<void> fetchSemuaDataPembayaran() async {
    change(null, status: RxStatus.loading());
    try {
      final profil = await _getProfilSiswa();
      nisn = profil['nisn'];
      sppPerBulan.value = profil['SPP'];
      tahunAjaran = await _getTahunAjaranTerakhir();
      idKelas = await _getKelasSiswa(nisn, tahunAjaran);

      await Future.wait([
        _prosesDataSpp(),
        _prosesPembayaranLain(),
      ]);
      change(null, status: RxStatus.success());
    } catch (e) {
      printError(info: e.toString());
      change(null, status: RxStatus.error("Gagal memuat data: ${e.toString()}"));
    }
  }

  // --- LOGIKA UTAMA YANG DIROMBAK TOTAL ---
  Future<void> _prosesDataSpp() async {
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(tahunAjaran)
        .collection('kelastahunajaran').doc(idKelas)
        .collection('daftarsiswa').doc(nisn)
        .collection('SPP').get();

    // Mengubah data dari Firestore menjadi Map yang lebih kaya informasi
    // Contoh: {'Juli': {'nominal': 150000, 'petugas': 'admin@sekolah.com', 'tglbayar': Timestamp(...)}}
    final Map<String, Map<String, dynamic>> sppSudahBayarData = {
      for (var doc in snapshot.docs) doc.id: doc.data()
    };

    bulanSudahBayar.value = sppSudahBayarData.length;
    totalKekuranganSpp.value = (12 - bulanSudahBayar.value) * sppPerBulan.value;

    List<BulanSppModel> listHasil = [];
    final now = DateTime.now();
    
    // Mendapatkan tahun awal dan akhir dari string tahun ajaran (misal: "2024-2025")
    final tahunAwal = int.parse(tahunAjaran.split('-')[0]);
    final tahunAkhir = int.parse(tahunAjaran.split('-')[1]);

    for (String namaBulan in bulanTahunAjaran) {
      final dataBayarBulanIni = sppSudahBayarData[namaBulan];
      final sudahBayar = dataBayarBulanIni != null;
      
      // Tentukan tahun untuk bulan ini dalam konteks tahun ajaran
      // Bulan Juli-Desember masuk tahun awal, Januari-Juni masuk tahun akhir
      final tahunBulanIni = (bulanTahunAjaran.indexOf(namaBulan) < 6) ? tahunAwal : tahunAkhir;
      // Konversi nama bulan ke nomor bulan
      var nomorBulanIni = bulanTahunAjaran.indexOf(namaBulan) % 12 + 7;
      if (nomorBulanIni > 12) nomorBulanIni -= 6;


      final tanggalBulanIni = DateTime(tahunBulanIni, (bulanTahunAjaran.indexOf(namaBulan) + 7) % 12);

      StatusPembayaran status;
      DateTime? tglBayar;
      String? petugas;

      if (sudahBayar) {
        status = StatusPembayaran.Lunas;
        // Ambil data detail pembayaran
        tglBayar = (dataBayarBulanIni['tglbayar'] as Timestamp?)?.toDate();
        petugas = dataBayarBulanIni['petugas'] as String?;
      } else {
        // Logika penentuan status berdasarkan tanggal di tahun ajaran
        if (now.year > tahunBulanIni || (now.year == tahunBulanIni && now.month >= (bulanTahunAjaran.indexOf(namaBulan) + 7)%12)) {
          status = StatusPembayaran.BelumLunas;
        } else {
          status = StatusPembayaran.AkanDatang;
        }
      }

      listHasil.add(BulanSppModel(
        namaBulan: namaBulan,
        nominalBayar: sppPerBulan.value,
        sudahDibayar: sudahBayar ? ((dataBayarBulanIni['nominal'] as num?)?.toInt() ?? 0) : 0,
        status: status,
        tglBayar: tglBayar,
        petugas: petugas,
      ));
    }
    daftarBulanSpp.value = listHasil;
  }

  Future<void> _prosesPembayaranLain() async {
    // Logika ini tetap sama dan sudah benar
    List<PembayaranLainModel> listHasil = [];
    for (String namaBiaya in jenisPembayaranLain) {
      final results = await Future.wait([
        firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(tahunAjaran).collection('biaya').doc(namaBiaya).get(),
        firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(tahunAjaran).collection('kelastahunajaran').doc(idKelas).collection('daftarsiswa').doc(nisn).collection('PembayaranLain').doc(namaBiaya).get()
      ]);
      final docKewajiban = results[0];
      final docSudahBayar = results[1];
      int nominalWajib = docKewajiban.exists ? ((docKewajiban.data()?['nominal'] as num?)?.toInt() ?? 0) : 0;
      int sudahDibayar = docSudahBayar.exists ? ((docSudahBayar.data()?['nominal'] as num?)?.toInt() ?? 0) : 0;
      if (nominalWajib > 0) {
        listHasil.add(PembayaranLainModel(nama: namaBiaya, nominalWajib: nominalWajib, sudahDibayar: sudahDibayar));
      }
    }
    daftarPembayaranLain.value = listHasil;
  }
  
  // --- Fungsi Helper ---
  Future<Map<String, dynamic>> _getProfilSiswa() async {
    final user = auth.currentUser!;
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('siswa').where('uid', isEqualTo: user.uid).limit(1).get();
    if (snapshot.docs.isEmpty) throw Exception("Data siswa tidak ditemukan.");
    final data = snapshot.docs.first.data();
    return {'nisn': snapshot.docs.first.id, 'SPP': (data['SPP'] as num?)?.toInt() ?? 0};
  }
  Future<String> _getTahunAjaranTerakhir() async { return "2024-2025"; }
  Future<String> _getKelasSiswa(String nisn, String thn) async { return "1A"; }
  
  String formatRupiah(int number) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  String formatTanggal(DateTime date) => DateFormat('d MMMM yyyy', 'id_ID').format(date);
}