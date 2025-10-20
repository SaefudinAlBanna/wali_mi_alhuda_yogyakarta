// views/daftar_nilai_matapelajaran_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/daftar_nilai_matapelajaran_controller.dart';

class DaftarNilaiMatapelajaranView extends GetView<DaftarNilaiMatapelajaranController> {
  const DaftarNilaiMatapelajaranView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.mapelData['namaMapel'] ?? 'Daftar Nilai'),
        flexibleSpace: Container( /* ... (dekorasi gradient yang sama) ... */ ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(child: Text(controller.errorMessage.value));
        }
        if (controller.daftarNilai.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada data penilaian untuk mata pelajaran ini.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: controller.daftarNilai.length,
          itemBuilder: (context, index) {
            final nilaiData = controller.daftarNilai[index];
            return _buildNilaiDetailCard(nilaiData);
          },
        );
      }),
    );
  }

  // WIDGET KARTU DETAIL NILAI (bisa di-copy dari jawaban sebelumnya)
  Widget _buildNilaiDetailCard(Map<String, dynamic> nilaiData) {
    final String nilai = (nilaiData['nilai'] ?? '0').toString();
    final String namaPenilaian = nilaiData['namaPenilaian'] ?? 'Tanpa Nama';
    final String jenisNilai = nilaiData['jenisNilai'] ?? 'Lainnya';
    final String deskripsi = nilaiData['deskripsi'] ?? '-';
    final Timestamp timestamp = nilaiData['tanggal'] ?? Timestamp.now();
    final String tanggal = DateFormat('d MMMM yyyy', 'id_ID').format(timestamp.toDate());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shadowColor: Colors.blueGrey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(namaPenilaian, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(jenisNilai, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.blueGrey.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  const SizedBox(height: 8),
                  Text('Deskripsi: $deskripsi', style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                  const SizedBox(height: 10),
                  Text(tanggal, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFF09203F),
              child: Text(nilai, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}