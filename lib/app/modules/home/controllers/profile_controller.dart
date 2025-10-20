// lib/app/modules/home/controllers/profile_controller.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/config_controller.dart';
import '../../../controllers/storage_controller.dart';
import '../../../controllers/account_manager_controller.dart';

class ProfileController extends GetxController {
  // --- DEPENDENSI ---
  final ConfigController configC = Get.find<ConfigController>();
  final StorageController storageC = Get.find<StorageController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final AccountManagerController accountManagerC = Get.find<AccountManagerController>();

  final isLoading = false.obs;
  final isSavingNama = false.obs;

  // --- FUNGSI UTAMA ---
  Future<void> ubahFotoProfil() async {
    try {
      // 1. Ambil gambar dari galeri
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return; // Pengguna membatalkan

      // 2. Crop gambar (UX yang bagus)
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(toolbarTitle: 'Pangkas Foto', lockAspectRatio: true),
          IOSUiSettings(title: 'Pangkas Foto', aspectRatioLockEnabled: true),
        ],
      );
      if (croppedFile == null) return; // Pengguna membatalkan crop

      // 3. Upload ke Supabase
      isLoading.value = true;
      final fileToUpload = File(croppedFile.path);
      final newUrl = await storageC.uploadProfilePicture(fileToUpload, configC.infoUser['uid']);

      if (newUrl != null) {
        // 4. Simpan URL baru ke Firestore
        await _firestore
            .collection('Sekolah').doc(configC.idSekolah)
            .collection('siswa').doc(configC.infoUser['uid'])
            .update({'fotoProfilUrl': newUrl});
        
        // 5. Perbarui state lokal agar UI langsung berubah
        configC.infoUser['fotoProfilUrl'] = newUrl;
        Get.snackbar('Berhasil', 'Foto profil berhasil diperbarui.');
      }
    } catch (e) {
      Get.snackbar('Gagal', 'Terjadi kesalahan saat mengubah foto.');
    } finally {
      isLoading.value = false;
    }
  }

  void showEditNamaDialog() {
    final peranKomite = configC.infoUser['peranKomite'] as Map<String, dynamic>?;
    if (peranKomite == null) return; // Pengaman

    final namaC = TextEditingController(text: peranKomite['namaOrangTua'] ?? '');

    Get.defaultDialog(
      title: "Ubah Nama Tampilan Komite",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Nama ini akan digunakan di semua fitur Komite."),
          const SizedBox(height: 16),
          TextField(
            controller: namaC,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Nama Tampilan Anda",
              hintText: "Contoh: Ayah Budi, Bunda Ani"
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: isSavingNama.value ? null : () {
          if (namaC.text.isNotEmpty) {
            Get.back();
            updateNamaTampilan(namaC.text);
          } else {
            Get.snackbar("Peringatan", "Nama tidak boleh kosong.");
          }
        },
        child: isSavingNama.value 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text("Simpan"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  Future<void> updateNamaTampilan(String namaBaru) async {
    isSavingNama.value = true;
    try {
      final uidSiswa = configC.infoUser['uid'];
      if (uidSiswa == null) throw Exception("UID Siswa tidak ditemukan.");

      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').doc(uidSiswa);

      // 1. Update ke Firestore menggunakan dot notation
      await siswaRef.update({'peranKomite.namaOrangTua': namaBaru});

      // 2. Update state lokal di ConfigController agar UI langsung berubah
      final Map<String, dynamic> peranKomiteLama = Map.from(configC.infoUser['peranKomite']);
      peranKomiteLama['namaOrangTua'] = namaBaru;
      configC.infoUser['peranKomite'] = peranKomiteLama;
      
      Get.snackbar("Berhasil", "Nama tampilan berhasil diubah menjadi: $namaBaru");

    } catch (e) {
      Get.snackbar("Error", "Gagal mengubah nama: ${e.toString()}");
    } finally {
      isSavingNama.value = false;
    }
  }
}