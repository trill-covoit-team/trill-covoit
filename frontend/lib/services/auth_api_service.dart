import 'package:trill_covoit/models/auth_session.dart';
import 'package:trill_covoit/services/api_client.dart';

class AuthApiService {
  final ApiClient _client;

  AuthApiService({required ApiClient apiClient}) : _client = apiClient;

  /// Inscription d'un nouvel utilisateur
  Future<String> register({
    required String email,
    required String password,
    required bool termsAccepted,
  }) async {
    final data = await _client.post(
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'termsAccepted': termsAccepted,
      },
    );
    return data['message'] as String? ?? 'Compte créé avec succès.';
  }

  /// Validation de l'adresse email avec le code à 6 chiffres
  Future<String> verifyEmail({
    required String email,
    required String code,
  }) async {
    final data = await _client.post(
      '/auth/verify-email',
      body: {
        'email': email,
        'code': code,
      },
    );
    return data['message'] as String? ?? 'Email validé avec succès.';
  }

  /// Connexion de l'utilisateur
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    return AuthSession.fromJson(data);
  }
}
