// app/models/nilai_halaqoh_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class NilaiHalaqoh {
  final String docId; // ID dokumen nilai spesifik
  final String pengampu;
  final DateTime tanggalInput;
  final String sabaq;
  final String nilaiSabaq;
  final String sabqi;
  final String nilaiSabqi;
  final String manzil;
  final String nilaiManzil;
  final String tugasTambahan;
  final String nilaiTugasTambahan;
  final String catatanPengampu;
  String catatanOrangTua;

  NilaiHalaqoh({
    required this.docId,
    required this.pengampu,
    required this.tanggalInput,
    required this.sabaq,
    required this.nilaiSabaq,
    required this.sabqi,
    required this.nilaiSabqi,
    required this.manzil,
    required this.nilaiManzil,
    required this.tugasTambahan,
    required this.nilaiTugasTambahan,
    required this.catatanPengampu,
    required this.catatanOrangTua,
    /* ... sisa field ... */
  });

 // --- DIUBAH: FACTORY CONSTRUCTOR SEKARANG MENERIMA DOCUMENTSNAPSHOT ---
  factory NilaiHalaqoh.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    // Ambil data dari dokumen dalam bentuk Map
    final data = doc.data();
    
    // Jika data null, kembalikan objek default untuk mencegah error
    if (data == null) {
      return NilaiHalaqoh(
        docId: doc.id,
        pengampu: '-',
        tanggalInput: DateTime.now(),
        sabaq: '-',
        nilaiSabaq: '-',
        sabqi: '-',
        nilaiSabqi: '-',
        manzil: '-',
        nilaiManzil: '-',
        tugasTambahan: '-',
        nilaiTugasTambahan: '-',
        catatanPengampu: '-',
        catatanOrangTua: '0',
      );
    }
    return NilaiHalaqoh(
      docId: doc.id,
      pengampu: data['namapengampu'] ?? '-',
      tanggalInput: DateTime.parse(data['tanggalinput']),
      sabaq: data['suratsabaq']?.isNotEmpty == true ? data['suratsabaq'] : data['sabaq'] ?? '-',
      nilaiSabaq: data['nilaisabaq']?.toString() ?? '-',
      sabqi: data['suratsabqi']?.isNotEmpty == true ? data['suratsabqi'] : data['sabqi'] ?? '-',
      nilaiSabqi: data['nilaisabqi']?.toString() ?? '-',
      manzil: data['suratmanzil']?.isNotEmpty == true ? data['suratmanzil'] : data['manzil'] ?? '-',
      nilaiManzil: data['nilaimanzil']?.toString() ?? '-',
      tugasTambahan: data['tugastambahan'] ?? '-',
      nilaiTugasTambahan: data['nilaitugastambahan']?.toString() ?? '-',
      catatanPengampu: data['keteranganpengampu'] ?? '-',
      catatanOrangTua: (data['keteranganorangtua'] != null && data['keteranganorangtua'] != "0") ? data['keteranganorangtua'] : "0",
    );
  }
}