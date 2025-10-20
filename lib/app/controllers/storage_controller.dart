// app/controllers/storage_controller.dart

import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageController extends GetxController {
  final supabase = Supabase.instance.client;

  // Fungsi untuk mengupload foto profil
  Future<String?> uploadProfilePicture(File file, String uid) async {
    try {
      // Tentukan path unik untuk setiap user berdasarkan Firebase UID mereka.
      // Format: 'public/profile/USER_UID.jpg'
      // Menggunakan timestamp untuk cache-busting jika user upload gambar baru
      final fileName = '$uid.jpg';
      final path = 'profile/$fileName';

      // Upload file. `upsert: true` akan menimpa file lama jika ada.
      await supabase.storage.from('profile').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Dapatkan URL publik dari file yang baru diupload
      final url = supabase.storage.from('profile').getPublicUrl(path);

      // --- CACHE BUSTING DIMULAI DI SINI ---
      // Tambahkan query parameter timestamp untuk memaksa refresh
      // DateTime.now().millisecondsSinceEpoch memastikan nilainya selalu unik

       final String cacheBustedUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      
      print('Original URL: $url');
      print('Cache Busted URL: $cacheBustedUrl');
      
      return cacheBustedUrl; // Kembalikan URL yang sudah dimodifikasi

    } catch (e) {
      Get.snackbar('Error', 'Gagal mengupload gambar: ${e.toString()}');
      print('Error uploading image: $e');
      return null;
    }
  }
}