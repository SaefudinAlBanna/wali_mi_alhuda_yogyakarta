// lib/app/models/komite_log_transaksi_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class KomiteLogTransaksiModel {
  final String id;
  // [DIUBAH] 'jenis' menjadi lebih deskriptif
  final String jenis; // 'Pemasukan' | 'Pengeluaran' | 'MASUK' | 'KELUAR'
  // [DIUBAH] 'deskripsi' menjadi opsional
  final String? deskripsi;
  final int nominal;
  // [DIUBAH] 'tanggal' menjadi 'timestamp' agar konsisten
  final DateTime timestamp;

  // --- FIELD BARU UNTUK MISI 7C ---
  final String? sumber;          // Untuk pemasukan (e.g., "Donasi Alumni")
  final String? tujuan;          // Untuk pengeluaran (e.g., "Beli ATK")
  final String? status;          // "pending", "disetujui", "ditolak"
  final String? pencatatNama;
  final String? alasanPenolakan; // Alasan jika pengeluaran ditolak

  KomiteLogTransaksiModel({
    required this.id,
    required this.jenis,
    this.deskripsi,
    required this.nominal,
    required this.timestamp,
    // Field baru
    this.sumber,
    this.tujuan,
    this.status,
    this.pencatatNama,
    this.alasanPenolakan,
  });

  factory KomiteLogTransaksiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    // Fallback untuk data lama yang menggunakan field 'tanggal'
    final tanggalData = data['timestamp'] ?? data['tanggal'];

    return KomiteLogTransaksiModel(
      id: doc.id,
      jenis: data['jenis'] ?? 'Pemasukan',
      deskripsi: data['deskripsi'],
      nominal: (data['nominal'] as num?)?.toInt() ?? 0,
      timestamp: (tanggalData as Timestamp? ?? Timestamp.now()).toDate(),
      // Baca field baru dari Firestore
      sumber: data['sumber'] as String?,
      tujuan: data['tujuan'] as String?,
      status: data['status'] as String?,
      pencatatNama: data['pencatatNama'] as String?,
      alasanPenolakan: data['alasanPenolakan'] as String?,
    );
  }
}


// // lib/app/models/komite_log_transaksi_model.dart

// import 'package:cloud_firestore/cloud_firestore.dart';

// class KomiteLogTransaksiModel {
//   final String id;
//   final String jenis; // 'MASUK' or 'KELUAR'
//   final String deskripsi;
//   final int nominal;
//   final DateTime tanggal;

//   KomiteLogTransaksiModel({
//     required this.id,
//     required this.jenis,
//     required this.deskripsi,
//     required this.nominal,
//     required this.tanggal,
//   });

//   factory KomiteLogTransaksiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
//     final data = doc.data() ?? {};
//     return KomiteLogTransaksiModel(
//       id: doc.id,
//       jenis: data['jenis'] ?? 'MASUK',
//       deskripsi: data['deskripsi'] ?? 'Tanpa Keterangan',
//       nominal: (data['nominal'] as num?)?.toInt() ?? 0,
//       tanggal: (data['tanggal'] as Timestamp? ?? Timestamp.now()).toDate(),
//     );
//   }
// }