// lib/app/modules/manajemen_komite_sekolah/views/manajemen_komite_sekolah_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/komite_anggota_model.dart';
import '../controllers/manajemen_komite_sekolah_controller.dart';

class ManajemenKomiteSekolahView extends GetView<ManajemenKomiteSekolahController> {
  const ManajemenKomiteSekolahView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Komite Sekolah'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!controller.isAuthorized.value) {
          return const Center(child: Text("Hanya Ketua Komite Sekolah yang dapat mengakses halaman ini."));
        }
        return RefreshIndicator(
          onRefresh: controller.fetchData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildKomiteSekolahCard(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildKomiteSekolahCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Anggota Komite Sekolah", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            Obx(() {
              if (controller.anggotaKomiteSekolah.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("Belum ada anggota yang ditunjuk."),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.anggotaKomiteSekolah.length,
                itemBuilder: (context, index) {
                  final anggota = controller.anggotaKomiteSekolah[index];
                  return _buildAnggotaTile(anggota);
                },
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              onPressed: controller.tambahAnggota,
              icon: const Icon(Icons.add),
              label: const Text("Tambah Anggota"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAnggotaTile(KomiteAnggotaModel anggota) {
    // Ketua Komite tidak bisa menghapus dirinya sendiri
    bool isSelf = anggota.uidSiswa == controller.accountManagerC.currentActiveStudent.value?.uid;

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(anggota.namaSiswa),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(anggota.jabatan, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (anggota.namaOrangTua != null) Text(anggota.namaOrangTua!),
        ],
      ),
      trailing: !isSelf ? IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () => controller.hapusAnggota(anggota),
      ) : null,
    );
  }
}