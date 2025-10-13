// lib/app/models/komite_transfer_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class KomiteTransferModel {
  final String id;
  final String dariKomiteId;
  final int nominal;
  final String status;
  final String diajukanOlehNama;
  final String diajukanOlehUid; // [BARU] Tambahkan field ini
  final DateTime tanggalAjuan;

  KomiteTransferModel({
    required this.id,
    required this.dariKomiteId,
    required this.nominal,
    required this.status,
    required this.diajukanOlehNama,
    required this.diajukanOlehUid, // [BARU] Tambahkan ke constructor
    required this.tanggalAjuan,
  });

  factory KomiteTransferModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return KomiteTransferModel(
      id: doc.id,
      dariKomiteId: data['dariKomiteId'] ?? 'N/A',
      nominal: (data['nominal'] as num?)?.toInt() ?? 0,
      status: data['status'] ?? 'pending',
      diajukanOlehNama: data['diajukanOlehNama'] ?? 'N/A',
      diajukanOlehUid: data['diajukanOlehUid'] ?? '', // [BARU] Baca dari Firestore
      tanggalAjuan: (data['tanggalAjuan'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}