import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kangal/data/services/secure_storage_service.dart';

/// A simple in-memory fake for FlutterSecureStorage used in tests.
class _FakeFlutterSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _values = {};

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _values.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    _values.clear();
    return Future.value();
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _values[key];
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_values);
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    return Future.value(_values.containsKey(key));
  }
}

void main() {
  late _FakeFlutterSecureStorage fakeStorage;
  late SecureStorageService service;

  setUp(() {
    fakeStorage = _FakeFlutterSecureStorage();
    service = SecureStorageService(storage: fakeStorage);
  });

  test('email credentials lifecycle', () async {
    expect(await service.hasEmailCredentials(), isFalse);
    expect(await service.getEmailCredentials(), isNull);

    await service.saveEmailCredentials('user@example.com', 'app-pass');

    expect(await service.hasEmailCredentials(), isTrue);
    final creds = await service.getEmailCredentials();
    expect(creds, isNotNull);
    expect(creds?.email, 'user@example.com');
    expect(creds?.appPassword, 'app-pass');

    await service.deleteEmailCredentials();
    expect(await service.hasEmailCredentials(), isFalse);
    expect(await service.getEmailCredentials(), isNull);
  });

  test('supabase token lifecycle', () async {
    expect(await service.getSupabaseToken(), isNull);

    await service.saveSupabaseToken('token-123');
    expect(await service.getSupabaseToken(), 'token-123');

    await service.deleteSupabaseToken();
    expect(await service.getSupabaseToken(), isNull);
  });
}
