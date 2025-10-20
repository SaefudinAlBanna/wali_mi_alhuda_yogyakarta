// lib/app/models/acara_kalender_model.dart (Salin dari Aplikasi Sekolah)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AcaraKalender {
  final String id;
  final String judul;
  final String deskripsi;
  final DateTime mulai;
  final DateTime selesai;
  final bool isLibur;
  final Color warna;

  AcaraKalender({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.mulai,
    required this.selesai,
    required this.isLibur,
    required this.warna,
  });

  factory AcaraKalender.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AcaraKalender(
      id: doc.id,
      judul: data['namaKegiatan'] ?? 'Tanpa Judul',
      deskripsi: data['deskripsi'] ?? '',
      mulai: (data['tanggalMulai'] as Timestamp).toDate(),
      selesai: (data['tanggalSelesai'] as Timestamp).toDate(),
      isLibur: data['isLibur'] ?? false,
      warna: _hexToColor(data['warnaHex'] ?? '#2196F3'), // Biru sebagai default
    );
  }

  static Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}