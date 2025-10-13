import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/jadwal_siswa_controller.dart';

class JadwalSiswaView extends GetView<JadwalSiswaController> {
  const JadwalSiswaView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Pelajaran Kelas'),
        bottom: TabBar(
          controller: controller.tabController,
          isScrollable: true,
          tabs: controller.daftarHari.map((hari) => Tab(text: hari)).toList(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoadingJadwal.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return TabBarView(
          controller: controller.tabController,
          children: controller.daftarHari.map((hari) {
            final jadwalHari = controller.jadwalPelajaran[hari] ?? [];
            if (jadwalHari.isEmpty) {
              return Center(
                child: Text(
                  "Tidak ada jadwal untuk hari ini.",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jadwalHari.length,
              itemBuilder: (context, index) {
                final pelajaran = jadwalHari[index];
                return _JadwalCard(pelajaran: pelajaran);
              },
            );
          }).toList(),
        );
      }),
    );
  }
}

class _JadwalCard extends StatelessWidget {
  final Map<String, dynamic> pelajaran;
  const _JadwalCard({required this.pelajaran});

  @override
  Widget build(BuildContext context) {
    // UI Card ini identik dengan versi Aplikasi Sekolah
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Get.theme.primaryColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              children: [
                Icon(Icons.access_time_filled_rounded, color: Colors.indigo.shade700, size: 28),
                const SizedBox(height: 4),
                Text(
                  pelajaran['jam'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pelajaran['namaMapel'] ?? 'Mata Pelajaran Belum Diatur',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Get.theme.primaryColorDark),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_rounded, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pelajaran['namaGuru'] ?? 'Guru Belum Diatur', // Ini akan menampilkan alias guru
                          style: TextStyle(color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}