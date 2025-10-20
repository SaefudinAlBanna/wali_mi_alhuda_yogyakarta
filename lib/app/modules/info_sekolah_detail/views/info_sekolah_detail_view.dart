import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

// Arahkan ke controller yang benar
import '../../info_sekolah_list/controllers/info_sekolah_list_controller.dart';

class InfoSekolahDetailView extends GetView<InfoSekolahListController> {
  const InfoSekolahDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ambil docId yang dikirim dari halaman daftar
    final String docId = Get.arguments;
    
    return Scaffold(
      // Gunakan FutureBuilder untuk mengambil data detail secara dinamis
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: controller.getInfoById(docId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Informasi tidak ditemukan."));
          }
          final data = snapshot.data!.data()!;
          
          final String judul = data['judul'] ?? 'Tanpa Judul';
          final String imageUrl = data['imageUrl'] ?? '';
          final String penulis = data['penulisNama'] ?? 'Admin';
          final String jabatan = data['peranPenulis'] ?? 'Staf';
          final String isi = data['isi'] ?? 'Tidak ada konten.';
          final DateTime tanggal = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

          // UI di bawah ini sama dengan versi superior dari aplikasi sekolah
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: _buildAppBarButton(
                  icon: Icons.arrow_back,
                  onPressed: () => Get.back(),
                ),
                actions: [
                  _buildAppBarButton(
                    icon: Icons.share,
                    onPressed: () => controller.shareInfo(data),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => Container(color: Colors.indigo.shade300),
                        placeholder: (c, u) => Container(color: Colors.grey.shade300),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        judul,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.3),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const CircleAvatar(radius: 24, child: Icon(Icons.person_outline_rounded)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(penulis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(jabatan, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.access_time_filled, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            timeago.format(tanggal, locale: 'id'),
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Text(
                        isi,
                        style: const TextStyle(fontSize: 16, height: 1.7, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBarButton({required IconData icon, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.4),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
      ),
    );
  }
}