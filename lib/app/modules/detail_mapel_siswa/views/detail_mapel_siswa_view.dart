import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../models/nilai_harian_model.dart';
import '../../../models/pengumuman_mapel_model.dart';
import '../controllers/detail_mapel_siswa_controller.dart';

class DetailMapelSiswaView extends GetView<DetailMapelSiswaController> {
  const DetailMapelSiswaView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(controller.namaMapel, style: const TextStyle(fontSize: 18)),
            Text(controller.namaGuru, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
        bottom: TabBar(
          controller: controller.tabController,
          tabs: const [
            Tab(text: 'Pengumuman'),
            Tab(text: 'Rincian Nilai'),
            Tab(text: 'Materi'),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: controller.dataMapel,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Data tidak ditemukan."));
          }

          final data = snapshot.data!;
          final List<PengumumanMapelModel> pengumuman = data['pengumuman'];
          final Map<String, dynamic> nilaiUtama = data['nilaiUtama'];
          final List<NilaiHarianModel> nilaiHarian = data['nilaiHarian'];

          return TabBarView(
            controller: controller.tabController,
            children: [
              _buildPengumumanTab(pengumuman),
              _buildNilaiTab(nilaiUtama, nilaiHarian),
              _buildMateriTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPengumumanTab(List<PengumumanMapelModel> listPengumuman) {
    if (listPengumuman.isEmpty) {
      return const Center(child: Text("Belum ada pengumuman (tugas/ulangan)."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: listPengumuman.length,
      itemBuilder: (context, index) {
        final item = listPengumuman[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              item.kategori.contains("PR") ? Icons.assignment_outlined : Icons.quiz_outlined,
              color: Get.theme.primaryColor,
            ),
            title: Text(item.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Catatan : ${item.catatan}", style: const TextStyle(fontSize: 12)),
                SizedBox(height: 10),
                Text("Diumumkan pada: ${DateFormat('dd MMM yyyy').format(item.tanggalDibuat)}"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNilaiTab(Map<String, dynamic> nilaiUtama, List<NilaiHarianModel> listNilaiHarian) {
    final int? nilaiPTS = nilaiUtama['nilai_pts'];
    final int? nilaiPAS = nilaiUtama['nilai_pas'];
    
    // Pisahkan nilai harian berdasarkan kategori
    final harianPR = listNilaiHarian.where((n) => n.kategori == 'Harian/PR' || n.kategori == 'PR').toList();
    final ulangan = listNilaiHarian.where((n) => n.kategori == 'Ulangan Harian').toList();
    final tambahan = listNilaiHarian.where((n) => n.kategori == 'Nilai Tambahan').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Nilai Utama (Sumatif)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _NilaiItemCard(label: "Penilaian Tengah Semester (PTS)", nilai: nilaiPTS),
        _NilaiItemCard(label: "Penilaian Akhir Semester (PAS)", nilai: nilaiPAS),
        const Divider(height: 32),

        _buildNilaiSection("Nilai Harian / PR", harianPR),
        _buildNilaiSection("Ulangan Harian", ulangan),
        _buildNilaiSection("Nilai Tambahan", tambahan),
      ],
    );
  }

  Widget _buildNilaiSection(String title, List<NilaiHarianModel> listNilai) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (listNilai.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Belum ada nilai.", style: TextStyle(color: Colors.grey)),
          )
        else
          ...listNilai.map((nilai) => _NilaiItemCard(
            label: nilai.catatan,
            nilai: nilai.nilai,
          )).toList(),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildMateriTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_rounded, size: 80, color: Colors.orange.shade700),
            const SizedBox(height: 16),
            const Text('Segera Hadir', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Fitur materi pelajaran sedang dalam pengembangan.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Helper untuk menampilkan item nilai dengan pewarnaan
class _NilaiItemCard extends StatelessWidget {
  final String label;
  final int? nilai;

  const _NilaiItemCard({required this.label, this.nilai});

  Color _getNilaiColor(int? n) {
    if (n == null) return Colors.grey;
    if (n >= 90) return Colors.green.shade700;
    if (n >= 80) return Colors.blue.shade700;
    if (n >= 70) return Colors.amber.shade800;
    if (n >= 60) return Colors.orange.shade700;
    if (n >= 50) return Colors.deepOrange.shade600;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(label),
        trailing: Container(
          width: 50,
          height: 35,
          decoration: BoxDecoration(
            color: _getNilaiColor(nilai).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getNilaiColor(nilai)),
          ),
          child: Center(
            child: Text(
              nilai?.toString() ?? '-',
              style: TextStyle(
                color: _getNilaiColor(nilai),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}