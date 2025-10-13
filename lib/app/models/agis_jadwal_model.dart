// lib/app/models/agis_jadwal_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AgisJadwalModel {
  final String id; // format: YYYY-MM-DD
  final DateTime tanggal;
  final String uidSiswaBertugas;
  final String namaSiswaBertugas;
  final String catatan;
  final String dibuatOlehUid;

  AgisJadwalModel({
    required this.id,
    required this.tanggal,
    required this.uidSiswaBertugas,
    required this.namaSiswaBertugas,
    required this.catatan,
    required this.dibuatOlehUid,
  });

  factory AgisJadwalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AgisJadwalModel(
      id: doc.id,
      tanggal: (data['tanggal'] as Timestamp? ?? Timestamp.now()).toDate(),
      uidSiswaBertugas: data['uidSiswaBertugas'] ?? '',
      namaSiswaBertugas: data['namaSiswaBertugas'] ?? 'Belum Ditentukan',
      catatan: data['catatan'] ?? '',
      dibuatOlehUid: data['dibuatOlehUid'] ?? '',
    );
  }

  String get namaHari => DateFormat('EEEE, dd MMM', 'id_ID').format(tanggal);
}