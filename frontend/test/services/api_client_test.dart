import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trill_covoit/exceptions/api_exception.dart';
import 'package:trill_covoit/services/api_client.dart';

void main() {
  const baseUrl = 'http://test.local/api';

  group('ApiClient', () {
    test('Exécute un appel POST et retourne le corps JSON décodé', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/test');
        expect(request.headers['Content-Type'], contains('application/json'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['key'], 'value');

        return http.Response(
          jsonEncode({'success': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(client: mockClient, baseUrl: baseUrl);
      final result = await client.post('/test', body: {'key': 'value'});

      expect(result['success'], isTrue);
    });

    test('Lève ApiException sans statut HTTP (null) en cas de timeout', () async {
      final mockClient = MockClient((request) async {
        throw TimeoutException('Timeout');
      });

      final client = ApiClient(client: mockClient, baseUrl: baseUrl);

      expect(
        () => client.post('/timeout'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', isNull)
              .having((e) => e.message, 'message', contains('délai d’attente')),
        ),
      );
    });

    test('Lève ApiException sans statut HTTP (null) en cas d\'erreur réseau (ClientException)', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connexion impossible');
      });

      final client = ApiClient(client: mockClient, baseUrl: baseUrl);

      expect(
        () => client.post('/client-error'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', isNull)
              .having((e) => e.message, 'message', contains('Impossible de joindre le serveur')),
        ),
      );
    });

    test('Transmet statusCode, message, errorCode et fieldErrors sur erreur HTTP', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'code': 'VALIDATION_ERROR',
            'message': 'Données erronées',
            'fieldErrors': {'email': 'Format invalide'},
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(client: mockClient, baseUrl: baseUrl);

      expect(
        () => client.post('/bad-request'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.errorCode, 'errorCode', 'VALIDATION_ERROR')
              .having((e) => e.fieldErrors, 'fieldErrors', {'email': 'Format invalide'}),
        ),
      );
    });

    test('Lève FormatException si le corps de réponse est un JSON invalide', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          'bad json content',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(client: mockClient, baseUrl: baseUrl);

      expect(
        () => client.post('/invalid-json'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
