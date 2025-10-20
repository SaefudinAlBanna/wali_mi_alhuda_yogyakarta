// lib/app/modules/semua_notifikasi/views/semua_notifikasi_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../models/notifikasi_model.dart';
import '../controllers/semua_notifikasi_controller.dart';

class SemuaNotifikasiView extends GetView<SemuaNotifikasiController> {
  const SemuaNotifikasiView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Notifikasi'),
        centerTitle: true,
        actions: [
          // Tombol untuk menghapus semua notifikasi
          IconButton(
            onPressed: controller.hapusSemuaNotifikasi,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: "Hapus Semua Notifikasi",
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.streamAllNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text("Tidak ada notifikasi.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;
          
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = NotifikasiModel.fromFirestore(notifications[index]);
              // Gunakan Dismissible untuk fungsionalitas geser-untuk-hapus
              return Dismissible(
                key: Key(notif.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) => controller.hapusNotifikasi(notif.id),
                background: Container(
                  color: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                ),
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getIconColor(notif.tipe).withOpacity(0.1),
                      child: Icon(_getIconData(notif.tipe), color: _getIconColor(notif.tipe)),
                    ),
                    title: Text(notif.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(notif.isi), // Tampilkan isi lengkap di sini
                    ),
                    // Tampilkan waktu yang lebih detail
                    trailing: Text(
                      DateFormat('dd MMM\nHH:mm').format(notif.tanggal),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper untuk memilih ikon berdasarkan tipe notifikasi
  IconData _getIconData(String tipe) {
    switch (tipe) {
      case 'NILAI_MAPEL': return Icons.grading_rounded;
      case 'TUGAS_BARU': return Icons.assignment_late_outlined;
      case 'ULANGAN_BARU': return Icons.quiz_outlined;
      case 'INFO_SEKOLAH': return Icons.campaign_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  // Helper untuk memilih warna ikon
  Color _getIconColor(String tipe) {
    switch (tipe) {
      case 'NILAI_MAPEL': return Colors.green.shade700;
      case 'TUGAS_BARU': return Colors.orange.shade800;
      case 'ULANGAN_BARU': return Colors.blue.shade700;
      case 'INFO_SEKOLAH': return Colors.purple.shade700;
      default: return Colors.grey.shade800;
    }
  }
}