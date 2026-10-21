import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:trill_covoit/core/constants/api_constants.dart';
import 'package:trill_covoit/exceptions/api_exception.dart';

class ApiClient {
  final http.Client _client;
  final String baseUrl;

  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConstants.baseUrl;

  static const _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Exécute une requête POST en sérialisant le corps en JSON
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final combinedHeaders = {..._defaultHeaders, ...?headers};

    final response = await _sendRequest(
      () => _client.post(
        uri,
        headers: combinedHeaders,
        body: body != null ? jsonEncode(body) : null,
      ),
    );

    return _handleResponse(response);
  }

  Future<http.Response> _sendRequest(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(ApiConstants.requestTimeout);
    } on TimeoutException {
      throw const ApiException(
        message: 'Le délai d’attente du serveur a expiré. Veuillez réessayer.',
        statusCode: 408,
      );
    } on SocketException {
      throw const ApiException(
        message: 'Impossible de joindre le serveur. Vérifiez votre connexion.',
        statusCode: 503,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Erreur réseau inattendue : $e',
        statusCode: 500,
      );
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (_) {}
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] ?? body['error'] ?? 'Une erreur est survenue (${response.statusCode})';
    final code = body['code'] as String?;

    throw ApiException(
      message: message.toString(),
      statusCode: response.statusCode,
      errorCode: code,
    );
  }
}
