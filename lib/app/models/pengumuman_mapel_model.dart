import 'package:cloud_firestore/cloud_firestore.dart';

class PengumumanMapelModel {
  final String id;
  final String judul;
  final String kategori; // PR, Ulangan, dll.
  final String catatan;
  final DateTime tanggalDibuat;

  PengumumanMapelModel({
    required this.id, required this.judul,
    required this.kategori,
    required this.catatan,
    required this.tanggalDibuat,
  });

  factory PengumumanMapelModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PengumumanMapelModel(
      id: doc.id,
      judul: data['judul'] ?? 'Tanpa Judul',
      kategori: data['kategori'] ?? 'Info',
      catatan: data['deskripsi'] ?? 'Belum ada catatan',
      tanggalDibuat: (data['tanggal_dibuat'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}