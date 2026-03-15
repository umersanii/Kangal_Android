import 'package:flutter_test/flutter_test.dart';
import 'package:gotrue/gotrue.dart';
import 'package:kangal/data/services/secure_storage_service.dart';
import 'package:kangal/data/services/supabase_auth_service.dart';

class _FakeSupabaseAuthClient implements SupabaseAuthClient {
  User? _currentUser;
  AuthResponse signUpResponse;
  AuthResponse signInResponse;
  bool signOutCalled = false;

  _FakeSupabaseAuthClient({
    required AuthResponse signUpResponse,
    required AuthResponse signInResponse,
    User? currentUser,
  }) : signUpResponse = signUpResponse,
       signInResponse = signInResponse,
       _currentUser = currentUser;

  @override
  User? get currentUser => _currentUser;

  set currentUser(User? user) => _currentUser = user;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = signInResponse.user;
    return signInResponse;
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    _currentUser = signUpResponse.user;
    return signUpResponse;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    _currentUser = null;
  }
}

class _FakeSecureStorageService extends SecureStorageService {
  String? _token;

  @override
  Future<void> saveSupabaseToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getSupabaseToken() async {
    return _token;
  }

  @override
  Future<void> deleteSupabaseToken() async {
    _token = null;
  }
}

User _user(String id) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    email: 'user@example.com',
  );
}

AuthResponse _authResponse({required String userId, required String token}) {
  final user = _user(userId);
  final session = Session(accessToken: token, tokenType: 'bearer', user: user);
  return AuthResponse(session: session, user: user);
}

void main() {
  test('signIn stores access token', () async {
    final storage = _FakeSecureStorageService();
    final client = _FakeSupabaseAuthClient(
      signUpResponse: _authResponse(userId: 'u1', token: 'signup.token'),
      signInResponse: _authResponse(userId: 'u1', token: 'signin.token'),
    );

    final service = SupabaseAuthService(
      authClient: client,
      secureStorageService: storage,
    );

    final response = await service.signIn('user@example.com', 'secret');

    expect(response.session?.accessToken, 'signin.token');
    expect(await storage.getSupabaseToken(), 'signin.token');
  });

  test('signOut clears stored token', () async {
    final storage = _FakeSecureStorageService();
    await storage.saveSupabaseToken('existing.token');

    final client = _FakeSupabaseAuthClient(
      signUpResponse: _authResponse(userId: 'u1', token: 'signup.token'),
      signInResponse: _authResponse(userId: 'u1', token: 'signin.token'),
      currentUser: _user('u1'),
    );

    final service = SupabaseAuthService(
      authClient: client,
      secureStorageService: storage,
    );

    await service.signOut();

    expect(client.signOutCalled, isTrue);
    expect(await storage.getSupabaseToken(), isNull);
  });

  test('isAuthenticated returns true when current user exists', () async {
    final storage = _FakeSecureStorageService();
    final client = _FakeSupabaseAuthClient(
      signUpResponse: _authResponse(userId: 'u1', token: 'signup.token'),
      signInResponse: _authResponse(userId: 'u1', token: 'signin.token'),
      currentUser: _user('u1'),
    );

    final service = SupabaseAuthService(
      authClient: client,
      secureStorageService: storage,
    );

    expect(await service.isAuthenticated(), isTrue);
    expect(service.getCurrentUserId(), 'u1');
  });

  test('isAuthenticated falls back to secure storage token', () async {
    final storage = _FakeSecureStorageService();
    await storage.saveSupabaseToken('persisted.token');

    final client = _FakeSupabaseAuthClient(
      signUpResponse: _authResponse(userId: 'u1', token: 'signup.token'),
      signInResponse: _authResponse(userId: 'u1', token: 'signin.token'),
      currentUser: null,
    );

    final service = SupabaseAuthService(
      authClient: client,
      secureStorageService: storage,
    );

    expect(await service.isAuthenticated(), isTrue);
    expect(service.getCurrentUserId(), isNull);
  });
}
