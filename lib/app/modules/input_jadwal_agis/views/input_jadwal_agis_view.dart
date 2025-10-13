import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/input_jadwal_agis_controller.dart';
import '../../../models/siswa_kelas_model.dart';


class InputJadwalAgisView extends GetView<InputJadwalAgisController> {
  const InputJadwalAgisView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Jadwal Snack'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!controller.isAuthorized.value) {
          return _buildUnauthorizedWidget();
        }
        return _buildForm(context);
      }),
    );
  }

  Widget _buildForm(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionTitle("1. Pilih Tanggal Jadwal", Icons.calendar_today),
        const SizedBox(height: 8),
        Obx(() => _buildDatePickerCard(context, controller.selectedDate.value)),
        const SizedBox(height: 24),

        _buildSectionTitle("2. Pilih Siswa Bertugas", Icons.person_search),
        const SizedBox(height: 8),
        Obx(() => _buildSiswaPickerCard(controller.daftarSiswa, controller.selectedSiswa.value)),
        const SizedBox(height: 24),
        
        _buildSectionTitle("3. Keterangan (Opsional)", Icons.edit_note),
        const SizedBox(height: 8),
        _buildKeteranganCard(),
        const SizedBox(height: 32),

        _buildSimpanButton(),
      ],
    );
  }

  // --- WIDGETS PEMBENTUK UI ---

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
      ],
    );
  }

  Widget _buildDatePickerCard(BuildContext context, DateTime? selectedDate) {
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: () => controller.pickDate(context),
        leading: const Icon(Icons.date_range, color: Colors.deepPurple),
        title: Text(
          selectedDate == null 
            ? 'Ketuk untuk memilih tanggal' 
            : DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(selectedDate),
          style: TextStyle(
            color: selectedDate == null ? Colors.grey[600] : Colors.black,
            fontWeight: selectedDate == null ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

  Widget _buildSiswaPickerCard(List<SiswaKelasModel> siswaList, SiswaKelasModel? selectedSiswa) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: DropdownButtonFormField<SiswaKelasModel>(
          value: selectedSiswa,
          isExpanded: true,
          decoration: const InputDecoration(
            border: InputBorder.none, // Hilangkan garis bawah
            icon: Icon(Icons.group, color: Colors.deepPurple),
            hintText: 'Pilih siswa yang bertugas',
          ),
          items: siswaList.map((siswa) {
            return DropdownMenuItem<SiswaKelasModel>(
              value: siswa,
              child: Text(siswa.nama),
            );
          }).toList(),
          onChanged: (newValue) {
            controller.selectedSiswa.value = newValue;
          },
        ),
      ),
    );
  }
  
  Widget _buildKeteranganCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextFormField(
          controller: controller.keteranganController,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Contoh: Snack sehat & buah',
            icon: Icon(Icons.fastfood_outlined, color: Colors.deepPurple),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSimpanButton() {
    return Obx(() => ElevatedButton.icon(
      icon: controller.isSaving.value
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.save),
      label: Text(controller.isSaving.value ? 'MENYIMPAN...' : 'SIMPAN JADWAL'),
      onPressed: controller.isSaving.value ? null : () => controller.simpanJadwal(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ));
  }

  Widget _buildUnauthorizedWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Akses Ditolak',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda harus menjadi "Admin AGIS" untuk mengakses halaman ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}