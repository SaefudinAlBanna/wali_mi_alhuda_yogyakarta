import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/catatan_bk_controller.dart';

class CatatanBkListView extends GetView<CatatanBkController> {
  const CatatanBkListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    controller.fetchCatatanList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Catatan Perkembangan'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isListLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarCatatan.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Belum ada catatan bimbingan atau perkembangan untuk Ananda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchCatatanList(),
          child: ListView.builder(
            itemCount: controller.daftarCatatan.length,
            itemBuilder: (context, index) {
              final catatan = controller.daftarCatatan[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    catatan.status == 'Ditutup' ? Icons.check_circle : Icons.chat_bubble_outline,
                    color: catatan.status == 'Ditutup' ? Colors.green : Colors.orange,
                  ),
                  title: Text(catatan.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Dari: ${catatan.pembuatNama}\n${DateFormat('dd MMMM yyyy', 'id_ID').format(catatan.tanggalDibuat)}'),
                  isThreeLine: true,
                  onTap: () => controller.goToDetail(catatan),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}