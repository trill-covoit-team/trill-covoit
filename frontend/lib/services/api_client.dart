import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:trill_covoit/core/constants/api_constants.dart';
import 'package:trill_covoit/exceptions/api_exception.dart';

class ApiClient {
  final http.Client _client;
  final String baseUrl;

  ApiClient({
    required http.Client client,
    required this.baseUrl,
  }) : _client = client;

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
    final encodedBody = body != null ? jsonEncode(body) : null;

    final response = await _sendRequest(
      () => _client.post(
        uri,
        headers: combinedHeaders,
        body: encodedBody,
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
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Impossible de joindre le serveur. Vérifiez votre connexion.',
      );
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded['message'] ??
        decoded['error'] ??
        'Une erreur est survenue (${response.statusCode})';
    final code = decoded['code'] as String?;
    final fieldErrors = decoded['fieldErrors'] as Map<String, dynamic>?;

    throw ApiException(
      message: message.toString(),
      statusCode: response.statusCode,
      errorCode: code,
      fieldErrors: fieldErrors,
    );
  }
}
