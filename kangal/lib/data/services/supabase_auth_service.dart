import 'package:kangal/data/services/secure_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthUnavailableException implements Exception {
  final String message;

  const SupabaseAuthUnavailableException(this.message);

  @override
  String toString() => message;
}

abstract class SupabaseAuthClient {
  User? get currentUser;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  });

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class SupabaseAuthClientAdapter implements SupabaseAuthClient {
  final GoTrueClient _client;

  SupabaseAuthClientAdapter(this._client);

  @override
  User? get currentUser => _client.currentUser;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.signUp(email: email, password: password);
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() {
    return _client.signOut();
  }
}

class SupabaseAuthService {
  SupabaseAuthClient? _authClient;
  final SecureStorageService _secureStorageService;

  SupabaseAuthService({
    SupabaseAuthClient? authClient,
    SecureStorageService? secureStorageService,
  }) : _authClient = authClient,
       _secureStorageService = secureStorageService ?? SecureStorageService();

  SupabaseAuthClient _getClientOrThrow() {
    if (_authClient != null) {
      return _authClient!;
    }

    try {
      _authClient = SupabaseAuthClientAdapter(Supabase.instance.client.auth);
      return _authClient!;
    } on AssertionError {
      throw const SupabaseAuthUnavailableException(
        'Supabase is not configured. Rebuild with SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
      );
    } catch (_) {
      throw const SupabaseAuthUnavailableException(
        'Supabase is unavailable in this app session. Check SUPABASE_URL/SUPABASE_ANON_KEY and restart the app.',
      );
    }
  }

  SupabaseAuthClient? _tryGetClient() {
    try {
      return _getClientOrThrow();
    } catch (_) {
      return null;
    }
  }

  Future<AuthResponse> signUp(String email, String password) async {
    final response = await _getClientOrThrow().signUp(
      email: email,
      password: password,
    );
    final accessToken = response.session?.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      await _secureStorageService.saveSupabaseToken(accessToken);
    }
    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _getClientOrThrow().signInWithPassword(
      email: email,
      password: password,
    );
    final accessToken = response.session?.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      await _secureStorageService.saveSupabaseToken(accessToken);
    }
    return response;
  }

  Future<void> signOut() async {
    await _getClientOrThrow().signOut();
    await _secureStorageService.deleteSupabaseToken();
  }

  Future<bool> isAuthenticated() async {
    try {
      final client = _tryGetClient();
      if (client?.currentUser != null) {
        return true;
      }
    } catch (_) {
      // Fallback to secure storage if Supabase client is unavailable
    }

    final token = await _secureStorageService.getSupabaseToken();
    return token != null && token.isNotEmpty;
  }

  String? getCurrentUserId() {
    try {
      return _tryGetClient()?.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  String? getCurrentUserEmail() {
    try {
      return _tryGetClient()?.currentUser?.email;
    } catch (_) {
      return null;
    }
  }
}
