// lib/app/modules/manajemen_iuran/views/manajemen_iuran_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/manajemen_iuran_controller.dart';

class ManajemenIuranView extends GetView<ManajemenIuranController> {
  const ManajemenIuranView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Iuran Komite'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!controller.isAuthorized.value) {
          return const Center(child: Text("Hanya Bendahara Kelas yang dapat mengakses halaman ini."));
        }
        return Column(
          children: [
            _buildMonthSelector(),
            _buildNominalInput(),
            const Divider(),
            Expanded(child: _buildSiswaList()),
          ],
        );
      }),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => controller.gantiBulan(-1)),
          Obx(() => Text(
            DateFormat.yMMMM('id_ID').format(controller.bulanTerpilih.value),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          )),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => controller.gantiBulan(1)),
        ],
      ),
    );
  }

  Widget _buildNominalInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: controller.nominalWajibC,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: "Nominal Iuran Wajib Bulan Ini",
          prefixText: "Rp ",
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildSiswaList() {
    return Obx(() {
      if (controller.daftarSiswaDenganStatus.isEmpty) {
        return const Center(child: Text("Tidak ada siswa di kelas ini."));
      }
      return ListView.builder(
        itemCount: controller.daftarSiswaDenganStatus.length,
        itemBuilder: (context, index) {
          final siswa = controller.daftarSiswaDenganStatus[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: siswa.sudahLunas ? Colors.green.shade50 : null,
            child: ListTile(
              leading: CircleAvatar(
                child: Text(siswa.namaLengkap.isNotEmpty ? siswa.namaLengkap[0] : '-'),
              ),
              title: Text(siswa.namaLengkap),
              subtitle: Text(siswa.sudahLunas ? "LUNAS (Rp ${NumberFormat.decimalPattern('id_ID').format(siswa.iuranBulanIni?.nominalBayar ?? 0)})" : "Belum Lunas",
                style: TextStyle(color: siswa.sudahLunas ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
              ),
              trailing: siswa.sudahLunas 
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    onPressed: controller.isProcessing.value ? null : () => controller.showPembayaranDialog(siswa),
                    child: const Text("Bayar"),
                  ),
            ),
          );
        },
      );
    });
  }
}