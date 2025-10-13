// lib/app/models/iuran_komite_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class IuranKomiteModel {
  final String id; // format: YYYY-MM
  final int nominalBayar;
  final String status;
  final DateTime tanggalBayar;
  final String dicatatOlehNama;

  IuranKomiteModel({
    required this.id,
    required this.nominalBayar,
    required this.status,
    required this.tanggalBayar,
    required this.dicatatOlehNama,
  });

  factory IuranKomiteModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return IuranKomiteModel(
      id: doc.id,
      nominalBayar: (data['nominalBayar'] as num?)?.toInt() ?? 0,
      status: data['status'] ?? 'Belum Lunas',
      tanggalBayar: (data['tanggalBayar'] as Timestamp? ?? Timestamp.now()).toDate(),
      dicatatOlehNama: data['dicatatOlehNama'] ?? 'N/A',
    );
  }
}