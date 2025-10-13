// lib/app/models/mapel_siswa_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MapelSiswaModel {
  final String id;
  final String namaMapel;
  final String namaGuru;
  final String? aliasGuru; // [BARU] Tambahkan field aliasGuru
  final double? nilaiAkhir;

  MapelSiswaModel({
    required this.id,
    required this.namaMapel,
    required this.namaGuru,
    this.aliasGuru, // [BARU] Tambahkan ke constructor
    this.nilaiAkhir,
  });

  factory MapelSiswaModel.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return MapelSiswaModel(
      id: doc.id,
      namaMapel: data['namaMapel'] ?? 'Tanpa Nama',
      namaGuru: data['namaGuru'] ?? 'N/A',
      aliasGuru: data['aliasGuruPencatatAkhir'] as String?, // [PERBAIKAN] Ambil dari field yang benar di Firestore
      nilaiAkhir: (data['nilai_akhir'] as num?)?.toDouble(),
    );
  }
}