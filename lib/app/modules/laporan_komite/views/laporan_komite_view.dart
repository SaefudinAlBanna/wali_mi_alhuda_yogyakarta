// lib/app/modules/laporan_komite/views/laporan_komite_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/laporan_komite_controller.dart';

class LaporanKomiteView extends GetView<LaporanKomiteController> {
  const LaporanKomiteView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Obx hanya membungkus Text judul yang reaktif
        // title: Obx(() => Text(controller.judulLaporan)),
        title: Text(controller.judulLaporan, style: const TextStyle(fontSize: 18, 
        fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // Obx hanya membungkus tombol PDF yang state-nya berubah
          Obx(() => controller.isProcessingPdf.value
            ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)))
            : IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: controller.exportPdf,
                tooltip: "Ekspor ke PDF",
              ),
          ),
        ],
      ),
      // [PERBAIKAN FINAL UTAMA]
      // Obx hanya bertugas memilih antara loading atau layout utama
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        // Setelah loading selesai, kembalikan Column statis.
        // Reaktivitas akan diurus oleh widget-widget di dalamnya.
        return Column(
          children: [
            _buildMonthSelector(),
            _buildSummaryCard(),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(alignment: Alignment.centerLeft, child: Text("Rincian Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ),
            Expanded(child: _buildTransactionList()),
          ],
        );
      }),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => controller.gantiBulan(-1)),
          // Obx hanya membungkus Text bulan
          Obx(() => Text(
            DateFormat.yMMMM('id_ID').format(controller.bulanTerpilih.value),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          )),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => controller.gantiBulan(1)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    // Obx membungkus Card karena semua isinya reaktif
    return Obx(() => Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem("Pemasukan", controller.totalPemasukan.value, Colors.green),
                _summaryItem("Pengeluaran", controller.totalPengeluaran.value, Colors.red),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Saldo Akhir Bulan Ini", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(controller.saldoAkhir),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            )
          ],
        ),
      ),
    ));
  }
  
  Widget _summaryItem(String title, int value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    // Obx membungkus ListView karena datanya reaktif
    return Obx(() {
      if (controller.daftarTransaksi.isEmpty) {
        return const Center(child: Text("Tidak ada transaksi pada bulan ini."));
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: controller.daftarTransaksi.length,
        itemBuilder: (context, index) {
          final trx = controller.daftarTransaksi[index];
          bool isPemasukan = trx.jenis == 'Pemasukan' || trx.jenis == 'MASUK';
          String title = trx.sumber ?? trx.tujuan ?? trx.deskripsi ?? 'Transaksi';
          if(trx.jenis == 'Pengeluaran' && trx.status != 'disetujui') {
            title += ' (${trx.status})';
          }

          return ListTile(
            leading: Icon(
              isPemasukan ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPemasukan ? Colors.green : Colors.red,
            ),
            title: Text(title),
            subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(trx.timestamp)),
            trailing: Text(
              "${isPemasukan ? '+' : '-'} ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(trx.nominal)}",
              style: TextStyle(fontWeight: FontWeight.bold, color: isPemasukan ? Colors.green : Colors.red),
            ),
          );
        },
      );
    });
  }
}