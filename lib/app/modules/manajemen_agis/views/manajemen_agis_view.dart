// lib/app/modules/manajemen_agis/views/manajemen_agis_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/agis_jadwal_model.dart';
import '../controllers/manajemen_agis_controller.dart';

class ManajemenAgisView extends GetView<ManajemenAgisController> {
  const ManajemenAgisView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal AGIS Kelas'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildWeekSelector(),
            _buildCatatanUmumCard(),
            const Divider(height: 1),
            Expanded(child: _buildJadwalList()),
          ],
        );
      }),
    );
  }

  Widget _buildWeekSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => controller.gantiMinggu(-1)),
          Obx(() {
            final start = controller.tanggalAwalMinggu.value;
            final end = start.add(const Duration(days: 4));
            return Text(
              "${DateFormat('dd MMM', 'id_ID').format(start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(end)}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            );
          }),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => controller.gantiMinggu(1)),
        ],
      ),
    );
  }

  Widget _buildCatatanUmumCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        color: Colors.blue.shade50,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.shade200)
        ),
        child: ListTile(
          leading: const Icon(Icons.info_outline, color: Colors.blue),
          title: const Text("Catatan Umum AGIS", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Obx(() => Text(controller.catatanUmumAgis.value)),
          trailing: Obx(() => controller.isPjAgis.value 
            ? IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: controller.editCatatanUmum,
              )
            : const SizedBox.shrink()
          ),
        ),
      ),
    );
  }

  // [PERBAIKAN KUNCI] Menghapus Obx di sini karena sudah ada di parent
  Widget _buildJadwalList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        // Obx dipindah ke dalam item individual untuk efisiensi
        return Obx(() {
          final tanggalHariIni = controller.tanggalAwalMinggu.value.add(Duration(days: index));
          final jadwal = controller.jadwalMingguIni.firstWhereOrNull((j) {
            return j.tanggal.year == tanggalHariIni.year &&
                   j.tanggal.month == tanggalHariIni.month &&
                   j.tanggal.day == tanggalHariIni.day;
          });
          return _buildJadwalCard(tanggalHariIni, jadwal);
        });
      },
    );
  }

  // [PERBAIKAN KUNCI] Kembali ke UI ListTile yang stabil
  Widget _buildJadwalCard(DateTime tanggal, AgisJadwalModel? jadwal) {
    bool isBertugas = jadwal != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isBertugas ? Colors.green.shade50 : null,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 0),
        title: Text(DateFormat('EEEE, dd MMMM', 'id_ID').format(tanggal), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          isBertugas ? jadwal.namaSiswaBertugas : "Belum ada yang bertugas",
          style: TextStyle(color: isBertugas ? Colors.green.shade800 : null),
        ),
        trailing: controller.isPjAgis.value
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'atur') {
                  controller.aturJadwal(tanggal);
                } else if (value == 'hapus' && jadwal != null) {
                  controller.hapusJadwal(jadwal.id);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'atur',
                  child: Text('Atur / Ubah Petugas'),
                ),
                if (isBertugas)
                  const PopupMenuItem<String>(
                    value: 'hapus',
                    child: Text('Hapus Jadwal', style: TextStyle(color: Colors.red)),
                  ),
              ],
            )
          : null, // Sembunyikan tombol jika bukan PJ AGIS
      ),
    );
  }
}