import 'package:cloud_firestore/cloud_firestore.dart';

class JadwalAgisModel {
  final String id; // doc ID (misal: '2024-05-27')
  final String nisnBertugas;
  final String namaSiswa;
  final String keterangan;
  final DateTime tanggal;

  JadwalAgisModel({
    required this.id,
    required this.nisnBertugas,
    required this.namaSiswa,
    required this.keterangan,
    required this.tanggal,
  });

  factory JadwalAgisModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return JadwalAgisModel(
      id: doc.id,
      nisnBertugas: data['nisn_bertugas'] ?? '',
      namaSiswa: data['nama_siswa'] ?? 'N/A',
      keterangan: data['keterangan'] ?? 'Snack Pilihan',
      // Firestore timestamp diubah ke DateTime
      tanggal: (data['tanggal'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nisn_bertugas': nisnBertugas,
      'nama_siswa': namaSiswa,
      'keterangan': keterangan,
      'tanggal': Timestamp.fromDate(tanggal),
    };
  }
}