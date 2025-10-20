// lib/app/models/komite_anggota_model.dart

class KomiteAnggotaModel {
  final String uidSiswa;
  final String namaSiswa;
  final String? namaOrangTua;
  final String jabatan;
  final String komiteId;

  KomiteAnggotaModel({
    required this.uidSiswa,
    required this.namaSiswa,
    this.namaOrangTua,
    required this.jabatan,
    required this.komiteId,
  });
}