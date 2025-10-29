import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/tagihan_model.dart';
import '../../../models/transaksi_model.dart';
import '../controllers/detail_keuangan_siswa_controller.dart';

class DetailKeuanganSiswaView extends GetView<DetailKeuanganSiswaController> {
  const DetailKeuanganSiswaView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          appBar: AppBar(title: const Text("Keuangan")),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      
      if (controller.tabTitles.isEmpty) {
        return Scaffold(
          appBar: AppBar(title: const Text("Keuangan")),
          body: const Center(child: Text("Belum ada data keuangan yang tersedia.")),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Rincian Keuangan'),
          bottom: TabBar(
            controller: controller.tabController,
            isScrollable: true,
            tabs: controller.tabTitles.map((title) => Tab(text: title)).toList(),
          ),
        ),
        body: Column( // [PERBAIKAN] Bungkus dengan Column
          children: [
            _buildTotalTunggakanCard(), // [BARU] Tambahkan kartu ringkasan
            Expanded( // [PERBAIKAN] Bungkus TabBarView dengan Expanded
              child: TabBarView(
                controller: controller.tabController,
                children: controller.tabTitles.map((title) {
                  if (title == "SPP") return _buildSppTab();
                  if (title == "Riwayat") return _buildRiwayatTab();
                  return _buildUmumTab(title);
                }).toList(),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTotalTunggakanCard() {
    return GestureDetector(
      onTap: controller.showDetailTunggakan, // <-- MEMBUAT KARTU BISA DI-KLIK
      child: Obx(() => Card(
        margin: const EdgeInsets.all(16),
        color: controller.totalTunggakan.value > 0 ? Colors.red.shade50 : Colors.green.shade50,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Tunggakan Saat Ini", style: TextStyle(fontWeight: FontWeight.bold)),
                  if (controller.totalTunggakan.value > 0)
                    Text("Ketuk untuk melihat rincian", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              Text(
                "Rp ${NumberFormat.decimalPattern('id_ID').format(controller.totalTunggakan.value)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: controller.totalTunggakan.value > 0 ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildSppTab() {
    return Obx(() {
      final tunggakan = controller.tagihanSPP.where((t) => t.isTunggakan).toList();
      final reguler = controller.tagihanSPP.where((t) => !t.isTunggakan).toList();
      
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (tunggakan.isNotEmpty) ...[
            _buildDividerTunggakan("Tunggakan SPP Tahun Lalu"),
            ...tunggakan.map((tagihan) => _buildSppCard(tagihan)),
            const SizedBox(height: 24),
            _buildDividerTunggakan("Tagihan SPP Tahun Ini"),
          ],
          ...reguler.map((tagihan) => _buildSppCard(tagihan)),
        ],
      );
    });
  }
  
  Widget _buildSppCard(TagihanModel tagihan) {
    final isLunas = tagihan.status == 'Lunas';
    final isJatuhTempo = !isLunas && tagihan.tanggalJatuhTempo != null && tagihan.tanggalJatuhTempo!.toDate().isBefore(DateTime.now());

    return Card(
      color: isLunas ? Colors.green.shade50 : (isJatuhTempo ? Colors.red.shade50 : null),
      child: ListTile(
        title: Text(tagihan.deskripsi, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Rp ${NumberFormat.decimalPattern('id_ID').format(tagihan.jumlahTagihan)}"),
        trailing: Text(
          isLunas ? "LUNAS" : (isJatuhTempo ? "JATUH TEMPO" : "BELUM LUNAS"),
          style: TextStyle(
            color: isLunas ? Colors.green : (isJatuhTempo ? Colors.red : Colors.orange),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUmumTab(String jenisPembayaran) {
    final List<TagihanModel> tagihanRelevant;
    if (jenisPembayaran == 'Uang Pangkal') {
      tagihanRelevant = controller.tagihanUangPangkal.value != null ? [controller.tagihanUangPangkal.value!] : [];
    } else {
      tagihanRelevant = controller.tagihanLainnya.where((t) => t.jenisPembayaran == jenisPembayaran).toList();
    }
    
    final tunggakan = tagihanRelevant.where((t) => t.isTunggakan).toList();
    final reguler = tagihanRelevant.where((t) => !t.isTunggakan).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (tunggakan.isNotEmpty) ...[
          _buildDividerTunggakan("Tunggakan Tahun Lalu"),
          ...tunggakan.map((tagihan) => _buildUmumCard(tagihan)),
          const SizedBox(height: 24),
           if (reguler.isNotEmpty) _buildDividerTunggakan("Tagihan Tahun Ini"),
        ],
        ...reguler.map((tagihan) => _buildUmumCard(tagihan)),
      ],
    );
  }

  Widget _buildUmumCard(TagihanModel tagihan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow("Total Tagihan", "Rp ${NumberFormat.decimalPattern('id_ID').format(tagihan.jumlahTagihan)}"),
            _buildDetailRow("Sudah Dibayar", "Rp ${NumberFormat.decimalPattern('id_ID').format(tagihan.jumlahTerbayar)}"),
            const Divider(),
            _buildDetailRow("Kekurangan", "Rp ${NumberFormat.decimalPattern('id_ID').format(tagihan.sisaTagihan)}", isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatTab() {
    return Obx(() {
      if (controller.riwayatTransaksi.isEmpty) {
        return const Center(child: Text("Belum ada riwayat pembayaran."));
      }
      return ListView.builder(
        // [PERBAIKAN] Ubah padding agar tidak tumpang tindih dengan kartu baru
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: controller.riwayatTransaksi.length,
        itemBuilder: (context, index) {
          final trx = controller.riwayatTransaksi[index];
          return Card(
            clipBehavior: Clip.antiAlias, // [PERBAIKAN] Tambahkan ini untuk efek InkWell
            child: InkWell( // [PERBAIKAN] Bungkus ListTile dengan InkWell
              onTap: () => controller.showDetailTransaksiDialog(trx), // <-- AKSI KLIK DI SINI
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text("Rp ${NumberFormat.decimalPattern('id_ID').format(trx.jumlahBayar)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if(trx.keterangan.isNotEmpty)
                      Text(trx.keterangan, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      "Dicatat oleh: ${trx.dicatatOlehNama} pada ${DateFormat('dd MMM yyyy, HH:mm').format(trx.tanggalBayar)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.info_outline, color: Colors.blue),
              ),
            ),
          );
        },
      );
    });
  }
  
  Widget _buildDividerTunggakan(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ),
        const Expanded(child: Divider()),
      ]),
    );
  }
  
  Widget _buildDetailRow(String title, String value, {bool isTotal = false}) {
    final textTheme = Theme.of(Get.context!).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
          Text(value, style: isTotal 
            ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade700) 
            : textTheme.bodyLarge),
        ],
      ),
    );
  }
}