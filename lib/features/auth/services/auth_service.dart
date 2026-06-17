import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_user.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  AuthService({required this.apiClient, required this.tokenStorage});

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.dio.post(
      '/login',
      data: {'email': email, 'password': password},
    );

    final data = response.data['data'];
    final token = data['token'];
    final userJson = data['user'];

    await tokenStorage.saveToken(token);

    return AuthUser.fromJson(userJson);
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await apiClient.dio.post(
      '/register',
      data: {'name': name, 'email': email, 'password': password,},
    );

    final data = response.data['data'];
    final token = data['token'];
    final userJson = data['user'];

    await tokenStorage.saveToken(token);

    return AuthUser.fromJson(userJson);
  }

  Future<AuthUser> me() async {
    final response = await apiClient.dio.get('/me');

    final userJson = response.data['data']['user'];

    return AuthUser.fromJson(userJson);
  }

  Future<void> logout() async {
    try {
      await apiClient.dio.post('/logout');
    } finally {
      await tokenStorage.deleteToken();
    }
  }

  Future<AuthUser> loginWithGoogle({String role = 'customer'}) async {
    final googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize(
      serverClientId: '71990617520-3302sitr2ukcj130j3r6gbpodd7q9dq8.apps.googleusercontent.com',
    );

    final googleUser = await googleSignIn.authenticate();

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception(
        'Google ID token is null. Check serverClientId and Google OAuth setup.',
      );
    }

    final response = await apiClient.dio.post(
      '/auth/google',
      data: {'id_token': idToken, 'role': role},
    );

    final data = response.data['data'];
    final token = data['token'];
    final userJson = data['user'];

    await tokenStorage.saveToken(token);

    return AuthUser.fromJson(userJson);
  }
}
