import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:trill_covoit/core/constants/api_constants.dart';
import 'package:trill_covoit/features/auth/models/auth_exception.dart';
import 'package:trill_covoit/features/auth/models/auth_session.dart';

class AuthApiService {
  final http.Client _client;
  final String _baseUrl;

  AuthApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConstants.baseUrl;

  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Inscription d'un nouvel utilisateur
  Future<String> register({
    required String email,
    required String password,
    bool termsAccepted = true,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/register');
    final body = jsonEncode({
      'email': email,
      'password': password,
      'termsAccepted': termsAccepted,
    });

    final response = await _sendRequest(() => _client.post(uri, headers: _headers, body: body));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['message'] as String? ?? 'Compte créé avec succès.';
    }

    throw _parseError(response);
  }

  /// Validation de l'adresse email avec le code à 6 chiffres
  Future<String> verifyEmail({
    required String email,
    required String code,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/verify-email');
    final body = jsonEncode({
      'email': email,
      'code': code,
    });

    final response = await _sendRequest(() => _client.post(uri, headers: _headers, body: body));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['message'] as String? ?? 'Email validé avec succès.';
    }

    throw _parseError(response);
  }

  /// Connexion de l'utilisateur
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    final body = jsonEncode({
      'email': email,
      'password': password,
    });

    final response = await _sendRequest(() => _client.post(uri, headers: _headers, body: body));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthSession.fromJson(data);
    }

    throw _parseError(response);
  }

  Future<http.Response> _sendRequest(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(ApiConstants.requestTimeout);
    } on TimeoutException {
      throw const AuthException(
        message: 'Le délai d’attente du serveur a expiré. Veuillez réessayer.',
      );
    } on SocketException {
      throw const AuthException(
        message: 'Impossible de joindre le serveur. Vérifiez votre connexion.',
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(message: 'Erreur réseau inattendue : $e');
    }
  }

  AuthException _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body['message'] ?? body['error'] ?? 'Une erreur est survenue (${response.statusCode})';
      final code = body['code'] as String?;
      return AuthException(
        message: message.toString(),
        statusCode: response.statusCode,
        errorCode: code,
      );
    } catch (_) {
      return AuthException(
        message: 'Erreur du serveur (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }
}
