// lib/app/modules/account_switcher/views/account_switcher_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/account_switcher_controller.dart'; // Gunakan AccountSwitcherController
import '../../../models/student_profile_preview_model.dart';
import '../../../routes/app_pages.dart';

class AccountSwitcherView extends GetView<AccountSwitcherController> {
  const AccountSwitcherView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beralih Akun Siswa'),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: Obx(() {
        if (controller.isProcessingAccount.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.storedStudentAccounts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Belum ada akun siswa yang tersimpan.", textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: controller.goToLoginToAddAccount,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text("Tambah Akun Siswa"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: controller.storedStudentAccounts.length + 1, // +1 untuk tombol tambah akun
          itemBuilder: (context, index) {
            if (index < controller.storedStudentAccounts.length) {
              final student = controller.storedStudentAccounts[index];
              final isActive = controller.currentActiveStudent.value?.uid == student.uid;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isActive ? 4 : 1,
                color: isActive ? Colors.indigo.shade50 : null,
                child: ListTile(
                  leading: _buildProfileAvatar(student),
                  title: Text(student.namaLengkap, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text("Kelas: ${student.kelasId}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isActive)
                        const Icon(Icons.check_circle, color: Colors.green, semanticLabel: "Akun Aktif")
                      else
                        IconButton(
                          icon: const Icon(Icons.switch_account, color: Colors.blue),
                          onPressed: () => controller.switchStudentAccount(student.uid),
                          tooltip: "Beralih ke akun ini",
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => controller.removeStudentAccount(student.uid),
                        tooltip: "Hapus akun dari daftar",
                      ),
                    ],
                  ),
                  onTap: isActive ? null : () => controller.switchStudentAccount(student.uid),
                ),
              );
            } else {
              // Tombol Tambah Akun
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  onPressed: controller.goToLoginToAddAccount,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text("Tambah Akun Siswa Lain"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              );
            }
          },
        );
      }),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: OutlinedButton.icon(
          onPressed: controller.isProcessingAccount.value ? null : () => controller.logoutAllAccounts(),
          icon: const Icon(Icons.logout),
          label: const Text("Logout Dari Semua Akun"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: BorderSide(color: Colors.red.shade200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(StudentProfilePreview student) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.indigo.shade400,
      backgroundImage: student.fotoProfilUrl != null && student.fotoProfilUrl!.isNotEmpty
          ? CachedNetworkImageProvider(student.fotoProfilUrl!)
          : null,
      child: student.fotoProfilUrl == null || student.fotoProfilUrl!.isEmpty
          ? Text(student.namaLengkap[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20))
          : null,
    );
  }
}