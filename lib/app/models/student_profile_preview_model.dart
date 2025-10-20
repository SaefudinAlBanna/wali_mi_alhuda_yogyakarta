// lib/app/models/student_profile_preview_model.dart

class StudentProfilePreview {
  final String uid;
  final String email; 
  final String passwordEncrypted;
  final String namaLengkap;
  final String kelasId;
  final String? fotoProfilUrl;
  final Map<String, dynamic>? peranKomite; // [BARU] Tambahkan field ini

  StudentProfilePreview({
    required this.uid,
    required this.email,
    required this.passwordEncrypted,
    required this.namaLengkap,
    required this.kelasId,
    this.fotoProfilUrl,
    this.peranKomite, // [BARU] Tambahkan ke constructor
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'passwordEncrypted': passwordEncrypted,
    'namaLengkap': namaLengkap,
    'kelasId': kelasId,
    'fotoProfilUrl': fotoProfilUrl,
    'peranKomite': peranKomite, // [BARU] Tambahkan ke JSON
  };

  factory StudentProfilePreview.fromJson(Map<String, dynamic> json) => StudentProfilePreview(
    uid: json['uid'],
    email: json['email'],
    passwordEncrypted: json['passwordEncrypted'],
    namaLengkap: json['namaLengkap'],
    kelasId: json['kelasId'],
    fotoProfilUrl: json['fotoProfilUrl'],
    peranKomite: json['peranKomite'] as Map<String, dynamic>?, // [BARU] Baca dari JSON
  );
}