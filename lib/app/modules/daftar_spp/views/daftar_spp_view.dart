import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/daftar_spp_controller.dart';
import '../../../models/pembayaran_model.dart';

class DaftarSppView extends GetView<DaftarSppController> {
  const DaftarSppView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat Pembayaran'),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.amberAccent, indicatorWeight: 3,
            labelColor: Colors.white, unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'SPP Bulanan', icon: Icon(Icons.calendar_month)),
              Tab(text: 'Pembayaran Lain', icon: Icon(Icons.receipt_long)),
            ],
          ),
        ),
        body: controller.obx(
          (state) => TabBarView(
            children: [_buildSppView(), _buildPembayaranLainView()],
          ),
          onLoading: const Center(child: CircularProgressIndicator()),
          onError: (error) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(error ?? 'Terjadi kesalahan', textAlign: TextAlign.center,))),
        ),
      ),
    );
  }

  // Widget untuk Tab SPP (tidak banyak berubah di sini)
  Widget _buildSppView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSppSummaryCard(),
        const SizedBox(height: 16),
        const Text("Rincian per Bulan:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Obx(() => Column(
          children: controller.daftarBulanSpp.map((bulan) => _buildSppMonthCard(bulan)).toList(),
        )),
      ],
    );
  }

  // --- WIDGET TILE BULANAN YANG DIROMBAK MENJADI CARD ---
  Widget _buildSppMonthCard(BulanSppModel bulan) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (bulan.status) {
      case StatusPembayaran.Lunas:
        statusColor = Colors.green.shade700;
        statusIcon = Icons.check_circle;
        statusText = 'LUNAS';
        break;
      case StatusPembayaran.BelumLunas:
        statusColor = Colors.red.shade700;
        statusIcon = Icons.error;
        statusText = 'TUNGGAKAN';
        break;
      case StatusPembayaran.AkanDatang:
        statusColor = Colors.grey.shade600;
        statusIcon = Icons.hourglass_empty;
        statusText = 'AKAN DATANG';
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: statusColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bulan.namaBulan, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            // Tampilkan detail pembayaran HANYA JIKA LUNAS
            if (bulan.status == StatusPembayaran.Lunas)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.receipt_long, "Nominal", controller.formatRupiah(bulan.sudahDibayar)),
                  const SizedBox(height: 6),
                  _buildDetailRow(Icons.calendar_today, "Tanggal Bayar", bulan.tglBayar != null ? controller.formatTanggal(bulan.tglBayar!) : '-'),
                  const SizedBox(height: 6),
                  _buildDetailRow(Icons.person, "Petugas", bulan.petugas ?? '-'),
                ],
              )
            else
              // Tampilkan nominal kewajiban jika belum lunas/akan datang
              _buildDetailRow(Icons.monetization_on, "Kewajiban", controller.formatRupiah(bulan.nominalBayar)),
          ],
        ),
      ),
    );
  }

  // Helper untuk baris detail di dalam card
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text("$label:", style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildSppSummaryCard() {
    return Card(
      elevation: 4,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ringkasan SPP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const Divider(),
            Obx(() => _buildSummaryRow("SPP per Bulan", controller.formatRupiah(controller.sppPerBulan.value), Icons.monetization_on)),
            const SizedBox(height: 8),
            Obx(() => _buildSummaryRow("Total Tunggakan", controller.formatRupiah(controller.totalKekuranganSpp.value), Icons.warning, color: Colors.red.shade700)),
            const SizedBox(height: 8),
            Obx(() => _buildSummaryRow("Bulan Terbayar", "${controller.bulanSudahBayar.value} dari 12 bulan", Icons.check_circle, color: Colors.green.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildSppMonthTile(BulanSppModel bulan) {
    Icon icon;
    Color color;
    String trailingText = controller.formatRupiah(bulan.nominalBayar);

    switch (bulan.status) {
      case StatusPembayaran.Lunas:
        icon = Icon(Icons.check_circle, color: Colors.green.shade700);
        color = Colors.green.shade700;
        break;
      case StatusPembayaran.BelumLunas:
        icon = Icon(Icons.error, color: Colors.red.shade700);
        color = Colors.red.shade700;
        break;
      case StatusPembayaran.AkanDatang:
        icon = Icon(Icons.hourglass_empty, color: Colors.grey.shade600);
        color = Colors.grey.shade600;
        trailingText = 'Belum Jatuh Tempo';
        break;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: icon,
        title: Text(bulan.namaBulan, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(trailingText, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  // --- WIDGET UNTUK TAB PEMBAYARAN LAIN ---
  Widget _buildPembayaranLainView() {
    return Obx(() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.daftarPembayaranLain.length,
      itemBuilder: (context, index) {
        final pembayaran = controller.daftarPembayaranLain[index];
        return _buildPembayaranLainCard(pembayaran);
      },
    ));
  }

  Widget _buildPembayaranLainCard(PembayaranLainModel pembayaran) {
    final double progress = pembayaran.nominalWajib > 0 ? pembayaran.sudahDibayar / pembayaran.nominalWajib : 0;
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(pembayaran.nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pembayaran.status == StatusPembayaran.Lunas ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pembayaran.status == StatusPembayaran.Lunas ? 'LUNAS' : 'BELUM LUNAS',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text("Kewajiban: ${controller.formatRupiah(pembayaran.nominalWajib)}"),
            const SizedBox(height: 4),
            Text("Telah Dibayar: ${controller.formatRupiah(pembayaran.sudahDibayar)}", style: const TextStyle(color: Colors.green)),
            const SizedBox(height: 4),
            Text("Sisa: ${controller.formatRupiah(pembayaran.sisa)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Colors.grey[300],
              color: Colors.blue[800],
            ),
          ],
        ),
      ),
    );
  }

  // Helper Row
  Widget _buildSummaryRow(String title, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.blue[800], size: 20),
        const SizedBox(width: 12),
        Text("$title: ", style: const TextStyle(fontSize: 15)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}