// lib/app/modules/ekskul_siswa/views/ekskul_siswa_view.dart (Aplikasi ORANG TUA)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/ekskul_model.dart';
import '../controllers/ekskul_siswa_controller.dart';

class EkskulSiswaView extends GetView<EkskulSiswaController> {
  const EkskulSiswaView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekstrakurikuler'),
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
            return _buildErrorView();
        }
      }),
    );
  }

  // --- [BARU] Widget untuk menampilkan pesan error ---
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text("Terjadi Kesalahan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() => Text(controller.errorMessage.value, textAlign: TextAlign.center)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: controller.loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text("Coba Lagi"),
            ),
          ],
        ),
      ),
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
            title: Text("Pendaftaran Sedang Dibuka!", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Silakan pilih ekstrakurikuler yang ingin diikuti oleh Ananda."),
          ),
        ),
        const SizedBox(height: 16),
        Obx(() => Column(
          children: controller.daftarEkskul.map((ekskul) => _buildEkskulPilihanCard(ekskul)).toList(),
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
            title: Text("Pendaftaran Saat Ini Ditutup", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Berikut adalah daftar ekskul yang diikuti oleh Ananda semester ini."),
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.daftarEkskul.isEmpty) {
            return const Center(child: Text("Ananda tidak terdaftar di ekskul manapun semester ini."));
          }
          return Column(
            children: controller.daftarEkskul.map((ekskul) => _buildEkskulTerdaftarCard(ekskul)).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildEkskulPilihanCard(EkskulModel ekskul) {
    // Gabungkan semua nama pembina menjadi satu string
    final namaPembinaStr = ekskul.listPembina.map((p) => p['nama']).join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Column(
          children: [
            ListTile(
              title: Text(ekskul.namaEkskul, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Pembina: ${namaPembinaStr.isNotEmpty ? namaPembinaStr : 'N/A'}"),
              trailing: Obx(() => Switch(
                value: controller.ekskulTerpilih[ekskul.id] ?? false,
                onChanged: (value) => controller.toggleEkskulSelection(ekskul, value),
              )),
            ),
            ExpansionTile(
              title: const Text("Lihat Detail"),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow("Deskripsi", ekskul.deskripsi),
                      _buildDetailRow("Jadwal", ekskul.jadwalTeks),
                      _buildDetailRow("Biaya", "Rp ${ekskul.biaya} / bulan"),
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

  Widget _buildEkskulTerdaftarCard(EkskulModel ekskul) {
    final namaPembinaStr = ekskul.listPembina.map((p) => p['nama']).join(', ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(ekskul.namaEkskul, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Pembina: ${namaPembinaStr.isNotEmpty ? namaPembinaStr : 'N/A'}"),
      ),
    );
  }

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