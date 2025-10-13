// lib/app/models/ekskul_model.dart (Aplikasi ORANG TUA - VERSI FINAL)
import 'package:cloud_firestore/cloud_firestore.dart';

class EkskulModel {
  final String id;
  final String namaEkskul;
  final String deskripsi;
  final String jadwalTeks;
  final int biaya;
  // --- [DIUBAH] Ganti Map tunggal menjadi List<dynamic> ---
  final List<dynamic> listPembina; 
  // --- [DIHAPUS] Kita tidak butuh 'pembina' atau 'namaPembina' lagi di sini ---

  EkskulModel({
    required this.id, required this.namaEkskul, required this.deskripsi,
    required this.jadwalTeks, required this.biaya,
    required this.listPembina, // <-- [DIUBAH]
  });

  factory EkskulModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return EkskulModel(
      id: doc.id,
      namaEkskul: data['namaEkskul'] ?? 'Tanpa Nama Ekskul',
      deskripsi: data['deskripsi'] ?? 'Tidak ada deskripsi.',
      jadwalTeks: data['jadwalTeks'] ?? 'Jadwal belum diatur.',
      biaya: data['biaya'] ?? 0,
      // --- [DIUBAH] Ambil data dari field 'listPembina' ---
      listPembina: List<dynamic>.from(data['listPembina'] ?? []),
    );
  }
}