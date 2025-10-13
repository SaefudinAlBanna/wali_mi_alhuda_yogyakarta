// lib/app/modules/kas_komite/views/kas_komite_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/komite_log_transaksi_model.dart';
import '../../../models/komite_transfer_model.dart';
import '../controllers/kas_komite_controller.dart';

class KasKomiteView extends GetView<KasKomiteController> {
  const KasKomiteView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          controller.isBendaharaKelas.value 
          ? 'Kas Komite Kelas ${controller.komiteId}' 
          : 'Kas Komite Pusat'
        )),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.komiteId.isEmpty) {
          return const Center(child: Text("Anda tidak memiliki peran komite yang sesuai untuk melihat halaman ini."));
        }
        return RefreshIndicator(
          onRefresh: () async => await controller.initialize(),
          child: ListView(
            children: [
              _buildSaldoCard(),
              if (controller.isBendaharaSekolah.value) _buildPendingSection(),
              _buildTransaksiSection(),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(() {
        if (controller.isBendaharaKelas.value) {
          return FloatingActionButton.extended(
            onPressed: controller.saldoKas.value > 0 ? controller.showDialogSetorDana : null,
            backgroundColor: controller.saldoKas.value > 0 ? Theme.of(context).colorScheme.primary : Colors.grey,
            label: const Text("Setor Dana"),
            icon: const Icon(Icons.upload_rounded),
          );
        }
        if (controller.isBendaharaSekolah.value) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'pengeluaran',
                onPressed: () => _showPengeluaranDialog(),
                label: const Text("Ajukan Pengeluaran"),
                icon: const Icon(Icons.arrow_upward_rounded),
                backgroundColor: Colors.orange,
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: 'pemasukan',
                onPressed: () => _showPemasukanDialog(),
                label: const Text("Catat Pemasukan"),
                icon: const Icon(Icons.arrow_downward_rounded),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildSaldoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.indigo.shade50,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              const Text("Saldo Kas Saat Ini", style: TextStyle(fontSize: 16, color: Colors.indigo)),
              const SizedBox(height: 8),
              Obx(() => Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(controller.saldoKas.value),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransaksiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text("Riwayat Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        Obx(() {
          if (controller.daftarTransaksi.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("Belum ada riwayat transaksi.")));
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.daftarTransaksi.length,
            itemBuilder: (context, index) {
              final trx = controller.daftarTransaksi[index];
              return _buildTransaksiTile(trx);
            },
          );
        }),
      ],
    );
  }

  Widget _buildTransaksiTile(KomiteLogTransaksiModel trx) {
    bool isPemasukan = trx.jenis == 'Pemasukan' || trx.jenis == 'MASUK';
    IconData icon = isPemasukan ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    Color color = isPemasukan ? Colors.green : Colors.red;
    String title = trx.sumber ?? trx.tujuan ?? trx.deskripsi ?? 'Transaksi';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(DateFormat.yMMMMEEEEd('id_ID').add_Hm().format(trx.timestamp)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${isPemasukan ? '+' : '-'} ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(trx.nominal)}",
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            if (trx.jenis == 'Pengeluaran') _buildStatusChip(trx.status),
          ],
        ),
        onTap: () => _showDetailDialog(trx),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color chipColor = Colors.grey;
    String label = "Unknown";
    if (status == 'pending') {
      chipColor = Colors.orange;
      label = "Pending";
    } else if (status == 'disetujui') {
      chipColor = Colors.green;
      label = "Disetujui";
    } else if (status == 'ditolak') {
      chipColor = Colors.red;
      label = "Ditolak";
    }
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
      backgroundColor: chipColor,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // Dialog untuk menampilkan detail transaksi
  void _showDetailDialog(KomiteLogTransaksiModel trx) {
    Get.defaultDialog(
      title: "Detail Transaksi",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow("Jenis:", trx.jenis),
          _detailRow("Judul:", trx.sumber ?? trx.tujuan ?? 'N/A'),
          if(trx.deskripsi != null && trx.deskripsi!.isNotEmpty) _detailRow("Keterangan:", trx.deskripsi!),
          _detailRow("Nominal:", "Rp ${NumberFormat.decimalPattern('id_ID').format(trx.nominal)}"),
          _detailRow("Tanggal:", DateFormat.yMMMMEEEEd('id_ID').add_Hm().format(trx.timestamp)),
          if(trx.pencatatNama != null) _detailRow("Dicatat Oleh:", trx.pencatatNama!),
          if(trx.status != null) _detailRow("Status:", trx.status!),
          if(trx.alasanPenolakan != null) _detailRow("Alasan Ditolak:", trx.alasanPenolakan!, isHighlight: true),
        ],
      ),
      actions: [
        if (controller.isKetuaSekolah.value && trx.status == 'pending')
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  _showAlasanPenolakanDialog(trx.id);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Tolak"),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  controller.setujuiPengeluaran(trx.id);
                },
                child: const Text("Setujui"),
              ),
            ],
          ),
      ],
    );
  }

  Widget _detailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: TextStyle(color: isHighlight ? Colors.red : null))),
        ],
      ),
    );
  }

  // --- Dialog-dialog baru ---
  void _showPemasukanDialog() {
    final sumberC = TextEditingController();
    final nominalC = TextEditingController();
    final keteranganC = TextEditingController();
    Get.defaultDialog(
      title: "Catat Pemasukan Lain",
      content: Column(children: [
        TextField(controller: sumberC, decoration: const InputDecoration(labelText: 'Sumber Pemasukan'), textCapitalization: TextCapitalization.words),
        TextField(controller: nominalC, decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp '), keyboardType: TextInputType.number),
        TextField(controller: keteranganC, decoration: const InputDecoration(labelText: 'Keterangan (Opsional)'), textCapitalization: TextCapitalization.sentences),
      ]),
      onConfirm: () {
        final nominal = int.tryParse(nominalC.text) ?? 0;
        if (sumberC.text.isNotEmpty && nominal > 0) {
          Get.back();
          controller.catatPemasukanLain(sumberC.text, nominal, keteranganC.text);
        } else {
          Get.snackbar("Input Tidak Valid", "Sumber dan Nominal wajib diisi dengan benar.");
        }
      },
      textConfirm: "Simpan",
    );
  }

  void _showPengeluaranDialog() {
    final tujuanC = TextEditingController();
    final nominalC = TextEditingController();
    final keteranganC = TextEditingController();
    Get.defaultDialog(
      title: "Ajukan Pengeluaran Dana",
      content: Column(children: [
        TextField(controller: tujuanC, decoration: const InputDecoration(labelText: 'Tujuan Pengeluaran'), textCapitalization: TextCapitalization.words),
        TextField(controller: nominalC, decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp '), keyboardType: TextInputType.number),
        TextField(controller: keteranganC, decoration: const InputDecoration(labelText: 'Keterangan (Opsional)'), textCapitalization: TextCapitalization.sentences),
      ]),
      onConfirm: () {
        final nominal = int.tryParse(nominalC.text) ?? 0;
        if (tujuanC.text.isNotEmpty && nominal > 0) {
          Get.back();
          controller.ajukanPengeluaran(tujuanC.text, nominal, keteranganC.text);
        } else {
          Get.snackbar("Input Tidak Valid", "Tujuan dan Nominal wajib diisi dengan benar.");
        }
      },
      textConfirm: "Ajukan",
    );
  }

  void _showAlasanPenolakanDialog(String logId) {
    final alasanC = TextEditingController();
    Get.defaultDialog(
      title: "Tolak Pengajuan",
      content: TextField(
        controller: alasanC,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Alasan Penolakan', hintText: 'Wajib diisi...'),
      ),
      onConfirm: () {
        if (alasanC.text.isNotEmpty) {
          Get.back();
          controller.tolakPengeluaran(logId, alasanC.text);
        } else {
          Get.snackbar("Peringatan", "Alasan penolakan wajib diisi.");
        }
      },
      textConfirm: "Tolak & Kirim",
    );
  }
  
  Widget _buildPendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text("Setoran Dana Masuk (Pending)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        Obx(() {
          if (controller.daftarTransferPending.isEmpty) {
            return const Card(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text("Tidak ada setoran dana yang menunggu persetujuan."),
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.daftarTransferPending.length,
            itemBuilder: (context, index) {
              final transfer = controller.daftarTransferPending[index];
              return _buildPendingCard(transfer);
            },
          );
        }),
      ],
    );
  }
  
  Widget _buildPendingCard(KomiteTransferModel transfer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Dari: Komite Kelas ${transfer.dariKomiteId}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Oleh: ${transfer.diajukanOlehNama}\nPada: ${DateFormat.yMd('id_ID').add_Hm().format(transfer.tanggalAjuan)}"),
              trailing: Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(transfer.nominal),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton.icon(
                onPressed: controller.isProcessing.value ? null : () => controller.terimaDana(transfer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white
                ),
                icon: controller.isProcessing.value
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle),
                label: const Text("Terima & Konfirmasi Dana"),
              )),
            )
          ],
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import '../../../models/komite_log_transaksi_model.dart';
// import '../../../models/komite_transfer_model.dart';
// import '../controllers/kas_komite_controller.dart';

// class KasKomiteView extends GetView<KasKomiteController> {
//   const KasKomiteView({Key? key}) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         // [PERBAIKAN] Judul AppBar sekarang dinamis
//         title: Obx(() => Text(
//           controller.isBendaharaKelas.value 
//           ? 'Kas Komite Kelas ${controller.komiteId}' 
//           : 'Kas Komite Pusat'
//         )),
//         centerTitle: true,
//       ),
//       body: Obx(() {
//         if (controller.isLoading.value) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         return RefreshIndicator(
//           onRefresh: () async {
//             await controller.fetchLogTransaksi();
//             if (controller.isBendaharaSekolah.value) {
//               await controller.fetchPendingTransfers();
//             }
//           },
//           child: ListView(
//             children: [
//               _buildSaldoCard(),
//               if (controller.isBendaharaSekolah.value) _buildPendingSection(),
//               _buildTransaksiSection(),
//             ],
//           ),
//         );
//       }),
//       floatingActionButton: Obx(() {
//         if (controller.isBendaharaKelas.value) {
//           return FloatingActionButton.extended(
//             onPressed: controller.saldoKas.value > 0 ? controller.showDialogSetorDana : null,
//             backgroundColor: controller.saldoKas.value > 0 ? Theme.of(context).colorScheme.primary : Colors.grey,
//             label: const Text("Setor Dana"),
//             icon: const Icon(Icons.upload_rounded),
//           );
//         }
//         // Di sini kita akan tambahkan FAB untuk Misi 7C
//         return const SizedBox.shrink();
//       }),
//     );
//   }

//   Widget _buildSaldoCard() {
//     return Card(
//       margin: const EdgeInsets.all(16),
//       color: Colors.indigo.shade50,
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Center(
//           child: Column(
//             children: [
//               const Text("Saldo Kas Saat Ini", style: TextStyle(fontSize: 16, color: Colors.indigo)),
//               const SizedBox(height: 8),
//               Obx(() => Text(
//                 NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(controller.saldoKas.value),
//                 style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo),
//               )),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTransaksiSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Padding(
//           padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
//           child: Text("Riwayat Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//         ),
//         Obx(() {
//           if (controller.daftarTransaksi.isEmpty) {
//             return const Center(child: Padding(
//               padding: EdgeInsets.all(32.0),
//               child: Text("Belum ada riwayat transaksi."),
//             ));
//           }
//           return ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: controller.daftarTransaksi.length,
//             itemBuilder: (context, index) {
//               final trx = controller.daftarTransaksi[index];
//               final isMasuk = trx.jenis == 'MASUK';
//               return ListTile(
//                 leading: Icon(
//                   isMasuk ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
//                   color: isMasuk ? Colors.green : Colors.red,
//                 ),
//                 title: Text(trx.deskripsi),
//                 subtitle: Text(DateFormat.yMMMMEEEEd('id_ID').add_Hm().format(trx.tanggal)),
//                 trailing: Text(
//                   "${isMasuk ? '+' : '-'} ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(trx.nominal)}",
//                   style: TextStyle(
//                     color: isMasuk ? Colors.green : Colors.red,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               );
//             },
//           );
//         }),
//       ],
//     );
//   }

//   Widget _buildPendingSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Padding(
//           padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
//           child: Text("Setoran Dana Masuk (Pending)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//         ),
//         Obx(() {
//           if (controller.daftarTransferPending.isEmpty) {
//             return const Card(
//               margin: EdgeInsets.symmetric(horizontal: 16),
//               child: ListTile(
//                 leading: Icon(Icons.check_circle_outline, color: Colors.green),
//                 title: Text("Tidak ada setoran dana yang menunggu persetujuan."),
//               ),
//             );
//           }
//           return ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: controller.daftarTransferPending.length,
//             itemBuilder: (context, index) {
//               final transfer = controller.daftarTransferPending[index];
//               return _buildPendingCard(transfer);
//             },
//           );
//         }),
//       ],
//     );
//   }

//   Widget _buildPendingCard(KomiteTransferModel transfer) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//       color: Colors.orange.shade50,
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ListTile(
//               contentPadding: EdgeInsets.zero,
//               title: Text("Dari: Komite Kelas ${transfer.dariKomiteId}", style: const TextStyle(fontWeight: FontWeight.bold)),
//               subtitle: Text("Oleh: ${transfer.diajukanOlehNama}\nPada: ${DateFormat.yMd('id_ID').add_Hm().format(transfer.tanggalAjuan)}"),
//               trailing: Text(
//                 NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(transfer.nominal),
//                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//               ),
//             ),
//             const SizedBox(height: 8),
//             SizedBox(
//               width: double.infinity,
//               child: Obx(() => ElevatedButton.icon(
//                 onPressed: controller.isProcessing.value ? null : () => controller.terimaDana(transfer),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white
//                 ),
//                 icon: controller.isProcessing.value
//                     ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                     : const Icon(Icons.check_circle),
//                 label: const Text("Terima & Konfirmasi Dana"),
//               )),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }