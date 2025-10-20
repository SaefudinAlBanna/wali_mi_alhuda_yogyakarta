// lib/app/modules/daftar_mata_pelajaran/views/daftar_mata_pelajaran_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/mapel_siswa_model.dart';
import '../controllers/daftar_mata_pelajaran_controller.dart';

class DaftarMataPelajaranView extends GetView<DaftarMataPelajaranController> {
  const DaftarMataPelajaranView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mata Pelajaran'),
        centerTitle: true,
      ),
      body: Obx(() {
        // [PERBAIKAN] Gunakan configC.isKonfigurasiLoading
        if (controller.configC.isKonfigurasiLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        // [PERBAIKAN] Gunakan configC.tahunAjaranAktif
        if (controller.configC.tahunAjaranAktif.value.contains("TIDAK_AKTIF")) {
          return const Center(child: Text("Data akademik belum tersedia."));
        }
        
        return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: controller.getMataPelajaranSiswa(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Belum ada mata pelajaran."));
            }

            final mapelList = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mapelList.length,
              itemBuilder: (context, index) {
                final mapel = MapelSiswaModel.fromFirestore(mapelList[index]);
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.withOpacity(0.1),
                      child: Icon(Icons.menu_book_rounded, color: Colors.indigo.shade700),
                    ),
                    title: Text(mapel.namaMapel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    // [PERBAIKAN] Gunakan aliasGuru dengan fallback ke namaGuru
                    subtitle: Text("Guru: ${mapel.aliasGuru ?? mapel.namaGuru}"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => controller.goToDetailMapel(mapel),
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }
}