import 'package:http/http.dart' as http;
import 'package:trill_covoit/exceptions/api_exception.dart';
import 'package:trill_covoit/exceptions/auth_exception.dart';
import 'package:trill_covoit/models/auth_session.dart';
import 'package:trill_covoit/services/api_client.dart';

class AuthApiService {
  final ApiClient _client;

  AuthApiService({ApiClient? apiClient, http.Client? client, String? baseUrl})
      : _client = apiClient ?? ApiClient(client: client, baseUrl: baseUrl);

  /// Inscription d'un nouvel utilisateur
  Future<String> register({
    required String email,
    required String password,
    required bool termsAccepted,
  }) async {
    try {
      final data = await _client.post(
        '/auth/register',
        body: {
          'email': email,
          'password': password,
          'termsAccepted': termsAccepted,
        },
      );
      return data['message'] as String? ?? 'Compte créé avec succès.';
    } on ApiException catch (e) {
      throw AuthException(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
      );
    }
  }

  /// Validation de l'adresse email avec le code à 6 chiffres
  Future<String> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final data = await _client.post(
        '/auth/verify-email',
        body: {
          'email': email,
          'code': code,
        },
      );
      return data['message'] as String? ?? 'Email validé avec succès.';
    } on ApiException catch (e) {
      throw AuthException(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
      );
    }
  }

  /// Connexion de l'utilisateur
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _client.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );
      return AuthSession.fromJson(data);
    } on ApiException catch (e) {
      throw AuthException(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
      );
    }
  }
}
