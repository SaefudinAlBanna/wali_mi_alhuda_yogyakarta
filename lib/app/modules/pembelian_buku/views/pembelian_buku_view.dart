import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/buku_model.dart';
import '../controllers/pembelian_buku_controller.dart';

class PembelianBukuView extends GetView<PembelianBukuController> {
  const PembelianBukuView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembelian Buku'),
        centerTitle: true,
      ),
      body: Obx(() {
        switch (controller.pageMode.value) {
          case PageMode.Loading:
            return const Center(child: CircularProgressIndicator());
          case PageMode.PendaftaranDibuka:
            return _buildPendaftaranDibukaView();
          case PageMode.PendaftaranDitutup:
            return _buildPendaftaranDitutupView();
          case PageMode.Error:
            return Center(child: Text(controller.errorMessage.value));
        }
      }),
    );
  }

  Widget _buildPendaftaranDibukaView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue.shade50,
          child: const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.blue),
            title: Text("Pemesanan Buku Dibuka!", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Silakan pilih buku atau paket yang ingin dibeli. Tagihan akan otomatis dibuat."),
          ),
        ),
        const SizedBox(height: 16),
        Obx(() => Column(
          children: controller.daftarBuku.map((buku) => _buildBukuPilihanCard(buku)).toList(),
        )),
      ],
    );
  }

  Widget _buildPendaftaranDitutupView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.grey.shade200,
          child: const ListTile(
            leading: Icon(Icons.lock_clock_rounded, color: Colors.grey),
            title: Text("Pemesanan Buku Ditutup", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Berikut adalah daftar buku yang Anda pesan semester ini."),
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final bukuTerdaftar = controller.daftarBuku.where((b) => controller.bukuTerpilih[b.id] == true).toList();
          if (bukuTerdaftar.isEmpty) {
            return const Center(child: Text("Anda tidak memesan buku semester ini."));
          }
          return Column(
            children: bukuTerdaftar.map((buku) => _buildBukuTerdaftarCard(buku)).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildBukuPilihanCard(BukuModel buku) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Column(
          children: [
            ListTile(
              title: Text(buku.namaItem, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Rp ${NumberFormat.decimalPattern('id_ID').format(buku.harga)}"),
              trailing: Obx(() => Switch(
                value: controller.bukuTerpilih[buku.id] ?? false,
                onChanged: controller.isSaving.value ? null : (value) => controller.toggleBukuSelection(buku, value),
              )),
            ),
            if (buku.deskripsi.isNotEmpty || buku.isPaket)
              ExpansionTile(
                title: const Text("Lihat Detail"),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (buku.deskripsi.isNotEmpty) _buildDetailRow("Deskripsi", buku.deskripsi),
                        if (buku.isPaket) _buildDetailRow("Isi Paket", buku.daftarBukuDiPaket.join('\n')),
                      ],
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildBukuTerdaftarCard(BukuModel buku) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(buku.namaItem, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Rp ${NumberFormat.decimalPattern('id_ID').format(buku.harga)}"),
      ),
    );
  }
  
  // ... (widget helper _buildDetailRow sama seperti di ekskul)
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value),
        ],
      ),
    );
  }
}