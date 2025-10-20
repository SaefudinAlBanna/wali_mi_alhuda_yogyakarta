import 'package:cloud_firestore/cloud_firestore.dart';

class NilaiHarianModel {
  final String id;
  final int nilai;
  final String catatan;
  final String kategori; // Harian/PR, Ulangan, Tambahan

  NilaiHarianModel({
    required this.id, required this.nilai,
    required this.catatan, required this.kategori,
  });

  factory NilaiHarianModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NilaiHarianModel(
      id: doc.id,
      nilai: data['nilai'] ?? 0,
      catatan: data['catatan'] ?? 'Tidak ada catatan',
      kategori: data['kategori'] ?? 'Lainnya',
    );
  }
}