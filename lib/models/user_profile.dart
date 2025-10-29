import 'dart:convert';

class UserProfile {
  final String? photoBase64;
  final String nom;
  final String prenom;
  final String pays;
  final String isoCode;
  final String dialCode;
  final String telephone;
  final String email;
  final String dateNaissance; // ISO 8601 yyyy-MM-dd
  final String? note;

  const UserProfile({
    this.photoBase64,
    required this.nom,
    required this.prenom,
    required this.pays,
    required this.isoCode,
    required this.dialCode,
    required this.telephone,
    required this.email,
    required this.dateNaissance,
    this.note,
  });

  String get fullName => '$prenom $nom';

  Map<String, dynamic> toJson() {
    return {
      'photo': photoBase64,
      'nom': nom,
      'prenom': prenom,
      'pays': pays,
      'iso': isoCode,
      'dial_code': dialCode,
      'telephone': telephone,
      'email': email,
      'date_naissance': dateNaissance,
      'note': note,
    };
  }

  static UserProfile fromJson(Map<String, dynamic> json) {
    return UserProfile(
      photoBase64: json['photo'] as String?,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      pays: json['pays'] as String? ?? '',
      isoCode: json['iso'] as String? ?? '',
      dialCode: json['dial_code'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateNaissance: json['date_naissance'] as String? ?? '',
      note: json['note'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static UserProfile fromJsonString(String source) => fromJson(jsonDecode(source) as Map<String, dynamic>);
}
