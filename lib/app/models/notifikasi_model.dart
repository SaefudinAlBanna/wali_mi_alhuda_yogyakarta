// lib/app/models/notifikasi_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class NotifikasiModel {
  final String id;
  final String judul;
  final String isi;
  final String tipe;
  final DateTime tanggal;
  final bool isRead;
  final String? deepLink;

  NotifikasiModel({
    required this.id,
    required this.judul,
    required this.isi,
    required this.tipe,
    required this.tanggal,
    required this.isRead,
    this.deepLink,
  });

  factory NotifikasiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NotifikasiModel(
      id: doc.id,
      judul: data['judul'] ?? 'Tanpa Judul',
      isi: data['isi'] ?? 'Tidak ada konten.',
      tipe: data['tipe'] ?? 'UMUM',
      tanggal: (data['tanggal'] as Timestamp? ?? Timestamp.now()).toDate(),
      isRead: data['isRead'] ?? false,
      deepLink: data['deepLink'],
    );
  }
}