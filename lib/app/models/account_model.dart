// app/models/account_model.dart
class Account {
  final String uid;
  final String email;
  // Anda bisa tambahkan displayName, photoURL jika perlu

  Account({required this.uid, required this.email});

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        uid: json['uid'] as String,
        email: json['email'] as String,
      );
}