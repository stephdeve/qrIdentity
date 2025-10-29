import 'dart:convert';

import 'package:qr_identity/models/user_profile.dart';

class ScanRecord {
  final int? id;
  final UserProfile profile;
  final DateTime scannedAt;

  const ScanRecord({
    this.id,
    required this.profile,
    required this.scannedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'json': jsonEncode(profile.toJson()),
      'scanned_at': scannedAt.toIso8601String(),
    };
  }

  static ScanRecord fromMap(Map<String, dynamic> map) {
    final String jsonStr = map['json'] as String;
    final profile = UserProfile.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    final scannedAt = DateTime.parse(map['scanned_at'] as String);
    return ScanRecord(
      id: map['id'] as int?,
      profile: profile,
      scannedAt: scannedAt,
    );
  }
}
