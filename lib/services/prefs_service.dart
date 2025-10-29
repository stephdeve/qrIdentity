import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_identity/models/user_profile.dart';

class PrefsService {
  static const _keyProfile = 'user_profile_json';

  static Future<bool> hasProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyProfile);
    }

  static Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyProfile);
    if (json == null) return null;
    try {
      return UserProfile.fromJsonString(json);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, profile.toJsonString());
  }

  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfile);
  }
}
