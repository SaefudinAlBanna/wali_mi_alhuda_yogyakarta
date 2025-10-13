import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/jadwal_agis_controller.dart';
import '../../../models/jadwal_agis_model.dart';

class JadwalAgisView extends GetView<JadwalAgisController> {
  const JadwalAgisView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi locale Indonesia untuk package intl
    // Pastikan Anda sudah menambahkan `flutter_localizations` di pubspec.yaml
    // dan mengaturnya di MaterialApp
    // initializeDateFormatting('id_ID', null); 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Snack (AGIS)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchJadwalAgis(),
          ),
        ],
      ),
      body: controller.obx(
        (listJadwal) => RefreshIndicator(
          onRefresh: () => controller.fetchJadwalAgis(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: listJadwal!.length,
            itemBuilder: (context, index) {
              final jadwal = listJadwal[index];
              final bool isJadwalSiswa = controller.nisnSiswa.value == jadwal.nisnBertugas;
              final bool isHariIni = controller.isToday(jadwal.tanggal);
              
              return _buildJadwalCard(jadwal, isJadwalSiswa, isHariIni);
            },
          ),
        ),
        // --- UI UNTUK STATE LAIN ---
        onLoading: const Center(child: CircularProgressIndicator(color: Colors.teal)),
        onEmpty: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Jadwal Belum Dibuat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Silakan hubungi admin sekolah untuk membuat jadwal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        onError: (error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Oops, Terjadi Kesalahan!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error ?? 'Tidak dapat mengambil data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  onPressed: () => controller.fetchJadwalAgis(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET UNTUK KARTU JADWAL
  Widget _buildJadwalCard(JadwalAgisModel jadwal, bool isJadwalSiswa, bool isHariIni) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: isHariIni ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isJadwalSiswa ? Colors.amber.shade700 : (isHariIni ? Colors.teal : Colors.transparent),
          width: isJadwalSiswa || isHariIni ? 2 : 0,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Tanggal
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.teal, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.formatTanggal(jadwal.tanggal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Baris Nama Siswa
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            "Petugas Snack",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          Text(
                            jadwal.namaSiswa,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Baris Keterangan Snack
                Row(
                  children: [
                    const Icon(Icons.bakery_dining_outlined, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            "Saran Snack",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          Text(
                            jadwal.keterangan,
                            style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // --- BANNER PENANDA ---
          if (isHariIni)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Text('HARI INI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          if (isJadwalSiswa)
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Jadwal Saya', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}