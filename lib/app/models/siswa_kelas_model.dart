class SiswaKelasModel {
  final String nisn;
  final String nama;

  SiswaKelasModel({required this.nisn, required this.nama});

  factory SiswaKelasModel.fromFirestore(String nisn, Map<String, dynamic> data) {
    return SiswaKelasModel(
      nisn: nisn,
      nama: data['namasiswa'] ?? 'Nama tidak ditemukan',
    );
  }
}