// lib/app/models/siswa_iuran_status_model.dart
import 'iuran_komite_model.dart';

class SiswaIuranStatus {
  final String uid;
  final String namaLengkap;
  final String? fotoProfilUrl;
  IuranKomiteModel? iuranBulanIni;

  SiswaIuranStatus({
    required this.uid,
    required this.namaLengkap,
    this.fotoProfilUrl,
    this.iuranBulanIni,
  });

  bool get sudahLunas => iuranBulanIni?.status == 'Lunas';
}