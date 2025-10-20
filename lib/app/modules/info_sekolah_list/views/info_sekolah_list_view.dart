import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../routes/app_pages.dart';
import '../controllers/info_sekolah_list_controller.dart';

class InfoSekolahListView extends GetView<InfoSekolahListController> {
  const InfoSekolahListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Semua Informasi")),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
         stream: controller.streamInfo, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada informasi."));
          }
          final daftarInfo = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: daftarInfo.length,
            itemBuilder: (context, index) {
              final doc = daftarInfo[index];
              final data = doc.data();
              final timestamp = data['timestamp'] as Timestamp?;
              final tanggal = timestamp?.toDate() ?? DateTime.now();
              final imageUrl = data['imageUrl'] as String? ?? '';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => Get.toNamed(Routes.INFO_SEKOLAH_DETAIL, arguments: doc.id),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110, height: 110,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl, fit: BoxFit.cover,
                          placeholder: (c, u) => Container(color: Colors.grey.shade200),
                          errorWidget: (c, u, e) => Container(color: Colors.grey.shade200, child: const Icon(Icons.newspaper, color: Colors.grey)),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(data['judul'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(data['isi'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.access_time_filled, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(timeago.format(tanggal, locale: 'id'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}