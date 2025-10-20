// controllers/input_info_sekolah_controller.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class InfoSekolahController extends GetxController {
  // --- UI Controllers ---
  final TextEditingController judulC = TextEditingController();
  final TextEditingController inputC = TextEditingController();

  // --- Services ---
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final supabase.SupabaseClient supabaseClient = supabase.Supabase.instance.client;

  // --- State ---
  final Rx<File?> imageFile = Rx<File?>(null);
  final RxBool isLoading = false.obs;
  String? idTahunAjaran;
  final String idSekolah = "P9984539";
  
  @override
  void onInit() {
    super.onInit();
    _getTahunAjaran();
  }

   Future<void> _getTahunAjaran() async {
    try {
      final snapshot = await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .orderBy('namatahunajaran', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        String tahunAjaranTerakhir = snapshot.docs.first.data()['namatahunajaran'];
        idTahunAjaran = tahunAjaranTerakhir.replaceAll("/", "-");
      } else {
        // Handle jika tidak ada tahun ajaran sama sekali
        Get.snackbar("Error Kritis", "Data Tahun Ajaran tidak ditemukan.");
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mendapatkan data tahun ajaran: $e");
    }
  }

  /// Memilih gambar dari galeri atau kamera
  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        imageFile.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memilih gambar: $e');
    }
  }
  
  void removeImage() {
    imageFile.value = null;
  }

  /// Mengupload gambar ke Supabase Storage
  Future<String?> _uploadImageToSupabase(File file, String docId) async {
    try {
      final String filePath = 'info.sekolah/$docId.jpg';
      await supabaseClient.storage.from('info.sekolah').upload(
        filePath,
        file,
        fileOptions: const supabase.FileOptions(cacheControl: '3600', upsert: true),
      );
      return supabaseClient.storage.from('info.sekolah').getPublicUrl(filePath);
    } catch (e) {
      Get.snackbar('Upload Gagal', 'Terjadi kesalahan saat mengupload gambar, Maksimal 200 KB.');
      print("pesan error Upload Gagal = $e");
      return null;
    }
  }

  /// Menyimpan semua informasi ke Firestore
  Future<void> simpanInfo() async {
    if (judulC.text.trim().isEmpty) {
      Get.snackbar('Validasi Gagal', 'Judul informasi tidak boleh kosong.');
      return;
    }
    if (inputC.text.trim().isEmpty) {
      Get.snackbar('Validasi Gagal', 'Isi informasi tidak boleh kosong.');
      return;
    }
    
     // --- PENGECEKAN KEAMANAN TAMBAHAN ---
    if (idTahunAjaran == null) {
      Get.snackbar("Error", "Data tahun ajaran belum siap. Mohon coba lagi sesaat.");
      return;
    }
    
    isLoading.value = true;
    
    try {
      final user = auth.currentUser;
      if (user == null || idTahunAjaran == null) {
        throw Exception("Sesi tidak valid atau tahun ajaran tidak ditemukan.");
      }

      // 1. Buat ID unik untuk dokumen Firestore
      final String docId = '${DateTime.now().millisecondsSinceEpoch}-${user.uid}';

      // 2. Upload gambar jika ada, dan dapatkan URL-nya
      String? imageUrl;
      if (imageFile.value != null) {
        imageUrl = await _uploadImageToSupabase(imageFile.value!, docId);
        if (imageUrl == null) { // Jika upload gagal, hentikan proses
          isLoading.value = false;
          return;
        }
      }

      // 3. Ambil data pegawai (penulis)
      final docPegawai = await firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(user.uid).get();
      final String namaPenginput = docPegawai.data()?['alias'] ?? 'Admin Komite';
      final String jabatanPenginput = docPegawai.data()?['role'] ?? 'Komite';

      // 4. Siapkan data untuk disimpan
      final Map<String, dynamic> dataToSave = {
        'iduser': user.uid,
        'idsekolah': idSekolah,
        'namapenginput': namaPenginput,
        'jabatanpenginput': jabatanPenginput,
        'judulinformasi': judulC.text.trim(),
        'informasisekolah': inputC.text.trim(),
        'tanggalinput': DateTime.now().toIso8601String(),
        'imageUrl': imageUrl ?? '', // Simpan URL atau string kosong
      };

      // 5. Simpan ke Firestore
      await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('informasisekolah').doc(docId)
          .set(dataToSave);
      
      Get.back();
      Get.snackbar('Sukses', 'Informasi berhasil dipublikasikan!', backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      
      Get.snackbar('Error', 'Gagal menyimpan informasi: $e');
      print("pesan error : $e");
    } finally {
      isLoading.value = false;
    }
  }
}




// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class InfoSekolahController extends GetxController {
//   TextEditingController inputC = TextEditingController();
//   TextEditingController judulC = TextEditingController();

//   FirebaseAuth auth = FirebaseAuth.instance;
//   FirebaseFirestore firestore = FirebaseFirestore.instance;

//   String idUser = FirebaseAuth.instance.currentUser!.uid;
//   String idSekolah = "P9984539";
//   String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

//   String? idTahunAjaran;

//   @override
//   void onInit() async {
//     super.onInit();
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     idTahunAjaran = tahunajaranya.replaceAll("/", "-");
//     update();
//   }

//   Future<String> getTahunAjaranTerakhir() async {
//     CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('tahunajaran');
//     QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
//         await colTahunAjaran.get();
//     List<Map<String, dynamic>> listTahunAjaran =
//         snapshotTahunAjaran.docs.map((e) => e.data()).toList();
//     String tahunAjaranTerakhir =
//         listTahunAjaran.map((e) => e['namatahunajaran']).toList().last;
//     return tahunAjaranTerakhir;
//   }

//   void test() {
//     DateTime now = DateTime.now();
//       String docIdInfoTahun = DateFormat.yMd().format(now).replaceAll('/', '-');

//     // DateTime now = DateTime.now();
//       String docIdInfoJamMenitDetik = DateFormat.Hms().format(now).replaceAll(':', '-');
//       String docIdInfo = ("$docIdInfoTahun/$docIdInfoJamMenitDetik").replaceAll('/', '-');

//       print("docIdInfo = $docIdInfo");
//   }

//   Future<void> simpanInfo() async {
//     if (inputC.text.isNotEmpty &&
//         idUser.isNotEmpty &&
//         idSekolah.isNotEmpty &&
//         emailAdmin.isNotEmpty &&
//         idTahunAjaran != null) {
//       // simpan info
//       DateTime now = DateTime.now();
//       String docIdInfoTahun = DateFormat.yMd().format(now).replaceAll('/', '-');

//     // DateTime now = DateTime.now();
//       String docIdInfoJamMenitDetik = DateFormat.Hms().format(now).replaceAll(':', '-');
//       String docIdInfo = ("$docIdInfoTahun/$docIdInfoJamMenitDetik").replaceAll('/', '-');

//       Query<Map<String, dynamic>> colPegawai = firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('siswa')
//           .where('uid', isEqualTo: idUser);

//       QuerySnapshot<Map<String, dynamic>> snapPegawai = await colPegawai.get();
//       if (snapPegawai.docs.isNotEmpty) {
//         Map<String, dynamic> dataSemester = snapPegawai.docs.first.data();
//         String namasiswa = dataSemester['nama'];
//         // String jabatan = dataSemester['role'];

//         await firestore
//             .collection('Sekolah')
//             .doc(idSekolah)
//             .collection('tahunajaran')
//             .doc(idTahunAjaran)
//             .collection('informasisekolah')
//             .doc(docIdInfo)
//             .set({
//               'iduser': idUser,
//               'idsekolah': idSekolah,
//               'namapenginput': "ummu $namasiswa",
//               'jabatanpenginput': "Komite Sekolah",
//               'emailadmin': emailAdmin,
//               'judulinformasi': judulC.text,
//               'informasisekolah': inputC.text,
//               'tanggalinput': now.toIso8601String(),

              
//             });

//             print("iduser = $idUser");
//             print("idsekolah = $idSekolah");
//             print("namasiswa = $namasiswa");
//             print("judulC.text = ${judulC.text}");
//             print("emailAdmin = $emailAdmin");
//             print("inputC.text = ${inputC.text}");
//       }

//       Get.back();

//       Get.snackbar(
//         'Informasi',
//         'Berhasil input Informasi',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.grey[350],
//       );

//       refresh();
//     }
//   }
// }
