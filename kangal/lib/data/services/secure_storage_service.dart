import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around [FlutterSecureStorage] providing high-level helpers
/// for storing credentials used by the app.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _prefix = 'kangal_';
  static const _emailKey = '${_prefix}email';
  static const _appPasswordKey = '${_prefix}app_password';
  static const _supabaseTokenKey = '${_prefix}supabase_token';

  /// Stores the email address and app password used for IMAP login.
  Future<void> saveEmailCredentials(String email, String appPassword) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _appPasswordKey, value: appPassword);
  }

  /// Returns stored email credentials, or null if not present.
  Future<({String email, String appPassword})?> getEmailCredentials() async {
    final email = await _storage.read(key: _emailKey);
    final pw = await _storage.read(key: _appPasswordKey);
    if (email == null || pw == null) return null;
    return (email: email, appPassword: pw);
  }

  /// Deletes stored email credentials.
  Future<void> deleteEmailCredentials() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _appPasswordKey);
  }

  /// Returns true if both email and app password are stored.
  Future<bool> hasEmailCredentials() async {
    final creds = await getEmailCredentials();
    return creds != null;
  }

  /// Save a Supabase auth token.
  Future<void> saveSupabaseToken(String token) async {
    await _storage.write(key: _supabaseTokenKey, value: token);
  }

  /// Retrieve stored Supabase token, or null if none.
  Future<String?> getSupabaseToken() async {
    return _storage.read(key: _supabaseTokenKey);
  }

  /// Delete Supabase token from secure storage.
  Future<void> deleteSupabaseToken() async {
    await _storage.delete(key: _supabaseTokenKey);
  }
}
