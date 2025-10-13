// lib/app/modules/laporan_komite/controllers/laporan_komite_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../controllers/account_manager_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/komite_log_transaksi_model.dart';

class LaporanKomiteController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final AccountManagerController accountManagerC = Get.find<AccountManagerController>();

  final isLoading = true.obs;
  final isProcessingPdf = false.obs;

  String komiteId = '';
  String judulLaporan = 'Laporan Kas Komite';
  // final judulLaporan = 'Laporan Kas Komite'.obs;

  
  final Rx<DateTime> bulanTerpilih = DateTime.now().obs;
  final RxList<KomiteLogTransaksiModel> daftarTransaksi = <KomiteLogTransaksiModel>[].obs;

  final RxInt totalPemasukan = 0.obs;
  final RxInt totalPengeluaran = 0.obs;
  int get saldoAkhir => totalPemasukan.value - totalPengeluaran.value;

  @override
  void onInit() {
    super.onInit();
    ever(bulanTerpilih, (_) => _fetchDataLaporan());
    _initialize();
  }

  Future<void> _initialize() async {
    _determineScope();
    await _fetchDataLaporan();
  }

  void _determineScope() {
    final peran = accountManagerC.currentActiveStudent.value?.peranKomite?['jabatan'];
    final kelasId = accountManagerC.currentActiveStudent.value?.kelasId;

    if (peran == 'Ketua Komite Sekolah' || peran == 'Bendahara Komite Sekolah') {
      komiteId = 'sekolah';
      judulLaporan = 'Laporan Kas Komite Sekolah';
    } else if (kelasId != null) {
      komiteId = kelasId.split('-').first;
      judulLaporan = 'Laporan Kas Komite Kelas $komiteId';
    }
  }

  Future<void> _fetchDataLaporan() async {
    if (komiteId.isEmpty) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      final startOfMonth = DateTime(bulanTerpilih.value.year, bulanTerpilih.value.month, 1);
      final endOfMonth = DateTime(bulanTerpilih.value.year, bulanTerpilih.value.month + 1, 0, 23, 59, 59);

      final snap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(configC.tahunAjaranAktif.value)
        .collection('komite').doc(komiteId)
        .collection('log_transaksi')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('timestamp', descending: false)
        .get();

      daftarTransaksi.assignAll(snap.docs.map((d) => KomiteLogTransaksiModel.fromFirestore(d)).toList());
      _calculateSummary();
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data laporan: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateSummary() {
    int pemasukan = 0;
    int pengeluaran = 0;
    for (var trx in daftarTransaksi) {
      if (trx.jenis == 'Pemasukan' || trx.jenis == 'MASUK') {
        pemasukan += trx.nominal;
      } else if (trx.jenis == 'Pengeluaran' || trx.jenis == 'KELUAR') {
        if (trx.status == 'disetujui' || trx.jenis == 'KELUAR') {
          pengeluaran += trx.nominal;
        }
      }
    }
    totalPemasukan.value = pemasukan;
    totalPengeluaran.value = pengeluaran;
  }

  void gantiBulan(int increment) {
    bulanTerpilih.value = DateTime(
      bulanTerpilih.value.year,
      bulanTerpilih.value.month + increment,
      1
    );
  }

  Future<void> exportPdf() async {
    // [VALIDASI]
    if (daftarTransaksi.isEmpty) {
      Get.snackbar("Tidak Ada Data", "Tidak ada data transaksi untuk diekspor pada bulan ini.",
        backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    isProcessingPdf.value = true;
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.poppinsRegular();
      final boldFont = await PdfGoogleFonts.poppinsBold();
      final logoImage = pw.MemoryImage((await rootBundle.load('assets/png/logo.png')).buffer.asUint8List());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => _buildPdfHeader(logoImage, boldFont),
          build: (context) => [
            _buildPdfSummary(boldFont, font),
            _buildPdfTable(font, boldFont),
          ],
        ),
      );
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'laporan_komite_${DateFormat('yyyy-MM').format(bulanTerpilih.value)}.pdf');
    } catch (e) {
      Get.snackbar("Error", "Gagal membuat file PDF: ${e.toString()}");
    } finally {
      isProcessingPdf.value = false;
    }
  }

  pw.Widget _buildPdfHeader(pw.MemoryImage logo, pw.Font boldFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(children: [
          pw.Image(logo, width: 40, height: 40),
          pw.SizedBox(width: 10),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("MI Al-Huda Yogyakarta", style: pw.TextStyle(font: boldFont, fontSize: 14)),
            pw.Text(judulLaporan, style: const pw.TextStyle(fontSize: 12)),
          ]),
        ]),
        pw.Text("Periode: ${DateFormat('MMMM yyyy', 'id_ID').format(bulanTerpilih.value)}", style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildPdfSummary(pw.Font boldFont, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 20),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem("Total Pemasukan", totalPemasukan.value, boldFont, font),
          _summaryItem("Total Pengeluaran", totalPengeluaran.value, boldFont, font),
          _summaryItem("Saldo Akhir", saldoAkhir, boldFont, font),
        ],
      ),
    );
  }
  
  pw.Widget _summaryItem(String title, int value, pw.Font boldFont, pw.Font font) {
    return pw.Column(children: [
      pw.Text(title, style: pw.TextStyle(font: font, fontSize: 10)),
      pw.SizedBox(height: 4),
      pw.Text(
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value),
        style: pw.TextStyle(font: boldFont, fontSize: 12),
      ),
    ]);
  }
  
  pw.Widget _buildPdfTable(pw.Font font, pw.Font boldFont) {
    final headers = ['No', 'Tanggal', 'Keterangan', 'Masuk', 'Keluar'];

    final data = daftarTransaksi.asMap().entries.map((entry) {
      int index = entry.key;
      KomiteLogTransaksiModel trx = entry.value;
      bool isPemasukan = trx.jenis == 'Pemasukan' || trx.jenis == 'MASUK';
      String keterangan = trx.sumber ?? trx.tujuan ?? trx.deskripsi ?? '';
      if(trx.jenis == 'Pengeluaran' && trx.status != 'disetujui') {
        keterangan += ' (${trx.status})';
      }

      // [PERBAIKAN KUNCI DI SINI]
      bool isPengeluaranValid = !isPemasukan && (trx.status == 'disetujui' || trx.jenis == 'KELUAR');

      return [
        (index + 1).toString(),
        DateFormat('dd/MM/yy').format(trx.timestamp),
        keterangan,
        isPemasukan ? NumberFormat.decimalPattern('id_ID').format(trx.nominal) : '0',
        isPengeluaranValid ? NumberFormat.decimalPattern('id_ID').format(trx.nominal) : '0',
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
    );
  }
}