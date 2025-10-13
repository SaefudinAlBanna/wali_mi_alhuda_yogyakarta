// Enum untuk status yang jelas dan type-safe
enum StatusPembayaran { Lunas, BelumLunas, AkanDatang }

class BulanSppModel {
  final String namaBulan;
  final int nominalBayar;
  final int sudahDibayar;
  final StatusPembayaran status;
  
  // --- PENAMBAHAN FIELD BARU ---
  final DateTime? tglBayar; // Nullable, karena hanya ada jika lunas
  final String? petugas;    // Nullable

  BulanSppModel({
    required this.namaBulan,
    required this.nominalBayar,
    required this.sudahDibayar,
    required this.status,
    this.tglBayar, // Opsional
    this.petugas,   // Opsional
  });
}

class PembayaranLainModel {
  final String nama;
  final int nominalWajib;
  final int sudahDibayar;
  final int sisa;
  final StatusPembayaran status;

  PembayaranLainModel({
    required this.nama,
    required this.nominalWajib,
    required this.sudahDibayar,
  }) : sisa = nominalWajib - sudahDibayar,
       status = (nominalWajib - sudahDibayar) <= 0 ? StatusPembayaran.Lunas : StatusPembayaran.BelumLunas;
}