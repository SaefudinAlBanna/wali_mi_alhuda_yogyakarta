import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/halaqah_setoran_ummi_model.dart';
import '../controllers/halaqah_ummi_riwayat_siswa_controller.dart';

class HalaqahUmmiRiwayatSiswaView
    extends GetView<HalaqahUmmiRiwayatSiswaController> {
  const HalaqahUmmiRiwayatSiswaView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progres Halaqah Ummi'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.activeStudentUid.value.isEmpty) {
          return const Center(child: Text("Siswa tidak aktif."));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProgresCard(),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.history, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Riwayat Setoran", style: Get.textTheme.titleLarge),
              ],
            ),
            const Divider(),
            _buildRiwayatList(),
          ],
        );
      }),
    );
  }

  // --- [KARTU PROGRES UTAMA - DIROMBAK TOTAL] ---
  Widget _buildProgresCard() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: controller.streamProgresSiswa(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Card(child: ListTile(title: Text("Memuat progres...")));
        }
        final data = snapshot.data!.data();
        final Map<String, dynamic> progresData = (data?['halaqahUmmi']?['progres'] as Map<String, dynamic>?) ??
                                                 {'tingkat': 'Jilid', 'detailTingkat': '1', 'halaman': 0};

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PENCAPAIAN TERKINI",
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildProgresIndicator(progresData),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper yang diadaptasi dari Aplikasi Sekolah
  Widget _buildProgresIndicator(Map<String, dynamic> progresData) {
    final tingkat = progresData['tingkat'] ?? 'Jilid';
    final detailTingkat = progresData['detailTingkat'] ?? '1';
    final halaman = progresData['halaman'] ?? 1;
    final color = _getJilidColor(detailTingkat);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "$tingkat $detailTingkat",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "Halaman $halaman",
            style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold),
          ),
        ),
        const Spacer(),
        const Icon(Icons.verified_user, color: Colors.green),
      ],
    );
  }

  // --- [DAFTAR RIWAYAT - DIROMBAK] ---
  Widget _buildRiwayatList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: controller.streamRiwayatSetoran(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text("Belum ada riwayat setoran."),
          ));
        }
        final riwayatList = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: riwayatList.length,
          itemBuilder: (context, index) {
            final setoran = HalaqahSetoranUmmiModel.fromFirestore(riwayatList[index]);
            return _buildRiwayatItem(setoran);
          },
        );
      },
    );
  }

  Widget _buildRiwayatItem(HalaqahSetoranUmmiModel setoran) {
    final statusColor = _getStatusColor(setoran.penilaian.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Text(
            setoran.penilaian.nilaiHuruf,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(setoran.tanggalSetor)),
        subtitle: Text(
          "Materi: ${setoran.materi.tingkat} ${setoran.materi.detailTingkat} Hal ${setoran.materi.halaman}",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Icon(Icons.keyboard_arrow_down, color: statusColor),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow("Status Penilaian", setoran.penilaian.status, color: statusColor),
                _buildDetailRow("Dinilai oleh", setoran.namaPenilai, color: Colors.grey),
                _buildDetailRow("Lokasi", setoran.lokasiAktual, color: Colors.grey),
                const Divider(),
                _buildCatatanSection(
                  "Catatan Pengampu",
                  setoran.catatanPengampu,
                  Icons.school,
                ),
                const SizedBox(height: 16),
                _buildCatatanSection(
                  "Tanggapan Anda",
                  setoran.catatanOrangTua,
                  Icons.edit_note,
                  onTap: () => controller.openCatatanOrangTuaDialog(setoran),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- [WIDGET HELPER] ---
  Color _getJilidColor(String detailTingkat) {
    switch (detailTingkat) {
      case '1': return Colors.red.shade600;
      case '2': return Colors.orange.shade600;
      case '3': return Colors.green.shade600;
      case '4': return Colors.blue.shade600;
      case '5': return Colors.pink.shade400;
      case '6': return Colors.purple.shade500;
      default: return Colors.grey.shade600;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Lancar':
        return Colors.green.shade700;
      case 'Perlu Perbaikan':
        return Colors.orange.shade800;
      case 'Mengulang':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailRow(String title, String value, {required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCatatanSection(String title, String content, IconData icon, {VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (onTap != null)
              IconButton(icon: Icon(Icons.edit, color: Get.theme.primaryColor), onPressed: onTap)
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content.isNotEmpty ? content : "Tidak ada catatan.",
            style: TextStyle(fontStyle: content.isNotEmpty ? FontStyle.normal : FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import '../../../models/halaqah_setoran_ummi_model.dart'; // Pastikan path model ini benar
// import '../controllers/halaqah_ummi_riwayat_siswa_controller.dart';

// class HalaqahUmmiRiwayatSiswaView extends GetView<HalaqahUmmiRiwayatSiswaController> {
//   const HalaqahUmmiRiwayatSiswaView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Progres Halaqah Ummi'),
//         centerTitle: true,
//       ),
//       body: Obx(() { // Bungkus dengan Obx agar rebuild saat activeStudentUid berubah
//         if (controller.activeStudentUid.value.isEmpty) {
//           return const Center(child: Text("Siswa tidak aktif."));
//         }
//         return ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             _buildProgresCard(),
//             const SizedBox(height: 24),
//             Text("Riwayat Setoran", style: Get.textTheme.titleLarge),
//             const Divider(),
//             _buildRiwayatList(),
//           ],
//         );
//       }),
//     );
//   }

//   Widget _buildProgresCard() {
//     return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//       stream: controller.streamProgresSiswa(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) return const Card(child: ListTile(title: Text("Memuat progres...")));

//         final data = snapshot.data!.data();
//         String progresText = "Progres belum diatur";
//         if (data != null && data.containsKey('halaqahUmmi')) {
//           final progres = data['halaqahUmmi']['progres'];
//           progresText = "${progres['tingkat']} ${progres['detailTingkat']} - Halaman ${progres['halaman']}";
//         }

//         return Card(
//           elevation: 4,
//           child: ListTile(
//             leading: const Icon(Icons.menu_book, size: 40),
//             title: const Text("PENCAPAIAN SAAT INI"),
//             subtitle: Text(progresText, style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildRiwayatList() {
//     return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//       stream: controller.streamRiwayatSetoran(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return const Center(child: Text("Belum ada riwayat setoran."));
//         }

//         final riwayatList = snapshot.data!.docs;

//         return ListView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemCount: riwayatList.length,
//           itemBuilder: (context, index) {
//             final setoran = HalaqahSetoranUmmiModel.fromFirestore(riwayatList[index]);
//             return _buildRiwayatItem(setoran);
//           },
//         );
//       },
//     );
//   }

//   Widget _buildRiwayatItem(HalaqahSetoranUmmiModel setoran) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: ExpansionTile(
//         leading: CircleAvatar(
//           backgroundColor: _getStatusColor(setoran.penilaian.status).withOpacity(0.2),
//           child: Text(
//             setoran.penilaian.nilaiHuruf,
//             style: TextStyle(color: _getStatusColor(setoran.penilaian.status), fontWeight: FontWeight.bold),
//           ),
//         ),
//         title: Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(setoran.tanggalSetor)),
//         subtitle: Text("Materi: ${setoran.materi.tingkat} ${setoran.materi.detailTingkat} Hal ${setoran.materi.halaman}"),
//         trailing: Text(
//           setoran.penilaian.status,
//           style: TextStyle(color: _getStatusColor(setoran.penilaian.status), fontWeight: FontWeight.bold),
//         ),
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildDetailRow("Dinilai oleh", setoran.namaPenilai),
//                 const Divider(),
//                 _buildCatatanSection(
//                   "Catatan Pengampu",
//                   setoran.catatanPengampu,
//                   Icons.school,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildCatatanSection(
//                   "Tanggapan Anda",
//                   setoran.catatanOrangTua,
//                   Icons.edit,
//                   onTap: () => controller.openCatatanOrangTuaDialog(setoran),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(title, style: const TextStyle(color: Colors.grey)),
//           Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

//   Widget _buildCatatanSection(String title, String content, IconData icon, {VoidCallback? onTap}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(icon, size: 16, color: Colors.grey[700]),
//             const SizedBox(width: 8),
//             Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//             const Spacer(),
//             if (onTap != null)
//               IconButton(icon: Icon(Icons.edit, color: Get.theme.primaryColor), onPressed: onTap)
//           ],
//         ),
//         const SizedBox(height: 4),
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.grey[100],
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Text(
//             content.isNotEmpty ? content : "Tidak ada catatan.",
//             style: TextStyle(fontStyle: content.isNotEmpty ? FontStyle.normal : FontStyle.italic),
//           ),
//         ),
//       ],
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'Lancar':
//         return Colors.green.shade700;
//       case 'Perlu Perbaikan':
//         return Colors.orange.shade800;
//       case 'Mengulang':
//         return Colors.red.shade700;
//       default:
//         return Colors.grey;
//     }
//   }
// }