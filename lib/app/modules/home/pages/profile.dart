// lib/app/modules/home/pages/profile.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart'; 

import '../../../controllers/config_controller.dart';
import '../../../controllers/account_manager_controller.dart'; 
import '../../../models/student_profile_preview_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart'; 
import '../controllers/profile_controller.dart';

class ProfilePage extends GetView<HomeController> { 
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // [PERBAIKAN] Gunakan Get.find() karena ProfileController sudah permanent
    final profileC = Get.find<ProfileController>(); 
    final configC = Get.find<ConfigController>();
    final accountManager = Get.find<AccountManagerController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Siswa'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_note_rounded), onPressed: () => controller.goToEditProfil()),
          IconButton(icon: const Icon(Icons.switch_account), onPressed: () => controller.goToAccountSwitcher()),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => controller.logout())
        ],
      ),
      body: Obx(() {
        final activeStudent = accountManager.currentActiveStudent.value;
        if (activeStudent == null || configC.infoUser.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildProfileHeader(configC.infoUser, profileC, activeStudent),
            const SizedBox(height: 24),
            
            // [INTEGRASI BARU]
            _buildKomiteSection(profileC),
            _buildLaporanTile(),

            _buildSectionHeader("Data Pribadi Siswa"),
            _buildInfoTile(Icons.badge_outlined, "Nama Lengkap", configC.infoUser['namaLengkap']),
            _buildInfoTile(Icons.cake_outlined, "TTL", "${configC.infoUser['tempatLahir'] ?? '-'}, ${formatTanggal(configC.infoUser['tanggalLahir'])}"),
            _buildInfoTile(Icons.wc_outlined, "Jenis Kelamin", configC.infoUser['jenisKelamin']),
            const SizedBox(height: 24),

            _buildSectionHeader("Data Akademik"),
            _buildInfoTile(Icons.school_outlined, "Kelas", configC.infoUser['kelasId'] ?? 'Belum ada kelas'),
            _buildInfoTile(Icons.tag_outlined, "NISN", configC.infoUser['nisn']),
            _buildInfoTile(Icons.alternate_email_outlined, "Email Login", configC.infoUser['email']),
            _buildInfoTile(Icons.payments_outlined, "SPP per Bulan", "Rp ${NumberFormat.decimalPattern('id_ID').format(configC.infoUser['spp'] ?? 0)}"),
            const SizedBox(height: 24),

            _buildSectionHeader("Data Orang Tua & Kontak"),
            _buildInfoTile(Icons.person_pin_outlined, "Nama Ayah", configC.infoUser['namaAyah']),
            _buildInfoTile(Icons.phone_iphone_outlined, "No. HP Ayah", configC.infoUser['noHpAyah']),
            _buildInfoTile(Icons.person_pin_outlined, "Nama Ibu", configC.infoUser['namaIbu']),
            _buildInfoTile(Icons.phone_android_outlined, "No. HP Ibu", configC.infoUser['noHpIbu']),
            _buildInfoTile(Icons.home_work_outlined, "Alamat Lengkap", configC.infoUser['alamatLengkap']),

          ],
        );
      }),
    );
  }

  Widget _buildLaporanTile() {
    final configC = Get.find<ConfigController>();
    final peranKomite = configC.infoUser['peranKomite'] as Map<String, dynamic>?;
    
    // Hanya tampilkan jika pengguna adalah anggota komite
    if (peranKomite == null) {
      return const SizedBox.shrink();
    }
  
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.assessment_outlined, color: Colors.indigo),
        title: const Text("Laporan Keuangan Komite"),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.toNamed(Routes.LAPORAN_KOMITE),
      ),
    );
  }

  // [WIDGET BARU]
  Widget _buildKomiteSection(ProfileController profileC) {
    return Obx(() {
      final peranKomite = profileC.configC.infoUser['peranKomite'] as Map<String, dynamic>?;
      if (peranKomite == null) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Informasi Komite"),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.badge_outlined, color: Colors.blue),
              title: Text(peranKomite['jabatan'] ?? 'Anggota Komite', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(peranKomite['namaOrangTua'] ?? 'Nama Belum Diatur'),
              trailing: const Icon(Icons.edit),
              onTap: profileC.showEditNamaDialog,
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData, ProfileController profileC, StudentProfilePreview activeStudent) {
    return Column(
      children: [
        Obx(() => Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: Get.theme.primaryColor.withOpacity(0.2),
              child: CircleAvatar(
                radius: 48,
                backgroundImage: userData['fotoProfilUrl'] != null && userData['fotoProfilUrl'].isNotEmpty
                    ? CachedNetworkImageProvider(userData['fotoProfilUrl'])
                    : null,
                child: (userData['fotoProfilUrl'] == null || userData['fotoProfilUrl'].isEmpty)
                  ? Text( (userData['namaLengkap'] ?? "S")[0].toUpperCase(), style: const TextStyle(fontSize: 40, color: Colors.white) )
                  : null,
                backgroundColor: Get.theme.primaryColor,
              ),
            ),
            if (profileC.isLoading.value)
              const CircularProgressIndicator()
            else
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  onTap: () => profileC.ubahFotoProfil(),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.camera_alt, size: 20),
                  ),
                ),
              )
          ],
        )),
        const SizedBox(height: 12),
        Text(userData['namaLengkap'] ?? 'Nama Siswa', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text("NISN: ${userData['nisn'] ?? '-'}", style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Get.theme.primaryColor),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, dynamic value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey.shade600),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value?.toString() ?? '-', style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  String formatTanggal(dynamic tanggal) {
    if (tanggal == null) return '-';
    if (tanggal is String) {
      try {
        final dt = DateTime.parse(tanggal);
        return DateFormat('dd MMMM yyyy', 'id_ID').format(dt);
      } catch (e) {
        return '-';
      }
    }
    return '-';
  }
}