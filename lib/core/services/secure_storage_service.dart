import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyToken = 'auth_token';
  static const _keyUserData = 'user_data';

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _keyToken, value: token);
      AppLogger.d('Token saved');
    } catch (e, s) {
      AppLogger.e('Failed to save token', e, s);
      rethrow;
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _keyToken);
    } catch (e, s) {
      AppLogger.e('Failed to read token', e, s);
      return null;
    }
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await _storage.write(key: _keyUserData, value: jsonEncode(userData));
      AppLogger.d('User data saved');
    } catch (e, s) {
      AppLogger.e('Failed to save user data', e, s);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final data = await _storage.read(key: _keyUserData);
      return data != null ? jsonDecode(data) : null;
    } catch (e, s) {
      AppLogger.e('Failed to read user data', e, s);
      return null;
    }
  }

  static Future<String?> getUserRole() async {
    try {
      final data = await getUserData();
      final role = data?['role'];
      AppLogger.d('getUserRole: $role, full data: $data');
      return role;
    } catch (e, s) {
      AppLogger.e('Failed to get user role', e, s);
      return null;
    }
  }

  static Future<String?> getUserId() async {
    final data = await getUserData();
    return data!['id'];
  }

  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      AppLogger.d('Storage cleared');
    } catch (e, s) {
      AppLogger.e('Failed to clear storage', e, s);
    }
  }
}
