import 'package:kangal/data/services/secure_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  SupabaseAuthClient get _client {
    return _authClient ??= SupabaseAuthClientAdapter(
      Supabase.instance.client.auth,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    final response = await _client.signUp(email: email, password: password);
    final accessToken = response.session?.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      await _secureStorageService.saveSupabaseToken(accessToken);
    }
    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _client.signInWithPassword(
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
    await _client.signOut();
    await _secureStorageService.deleteSupabaseToken();
  }

  Future<bool> isAuthenticated() async {
    try {
      if (_client.currentUser != null) {
        return true;
      }
    } catch (_) {
      // Fallback to secure storage if Supabase client is unavailable
    }

    final token = await _secureStorageService.getSupabaseToken();
    return token != null && token.isNotEmpty;
  }

  String? getCurrentUserId() {
    return _client.currentUser?.id;
  }

  String? getCurrentUserEmail() {
    return _client.currentUser?.email;
  }
}
