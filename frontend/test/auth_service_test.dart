import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trill_covoit/exceptions/api_exception.dart';
import 'package:trill_covoit/exceptions/auth_exception.dart';
import 'package:trill_covoit/services/api_client.dart';
import 'package:trill_covoit/services/auth_api_service.dart';

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

    test('Lève ApiException avec code 408 en cas de timeout', () async {
      final mockClient = MockClient((request) async {
        throw TimeoutException('Timeout');
      });

      final client = ApiClient(client: mockClient, baseUrl: baseUrl);

      expect(
        () => client.post('/timeout'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 408),
        ),
      );
    });

    test('Lève ApiException avec code 503 en cas d\'erreur réseau (SocketException)', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Connexion impossible');
      });

      final client = ApiClient(client: mockClient, baseUrl: baseUrl);

      expect(
        () => client.post('/socket-error'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });
  });

  group('AuthApiService.register', () {
    test('Retourne le message en cas de succès (201 Created)', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/auth/register');
        expect(request.method, 'POST');

        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['email'], 'etudiant@univ-tlse3.fr');
        expect(payload['password'], 'Password123!');
        expect(payload['termsAccepted'], isTrue);

        return http.Response(
          jsonEncode({
            'userId': 1,
            'email': 'etudiant@univ-tlse3.fr',
            'emailVerified': false,
            'message': 'Votre compte a été créé. Un code vous a été envoyé.',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(client: mockClient, baseUrl: baseUrl);
      final result = await service.register(
        email: 'etudiant@univ-tlse3.fr',
        password: 'Password123!',
        termsAccepted: true,
      );

      expect(result, contains('Votre compte a été créé'));
    });

    test('Lève AuthException avec code 409 si email déjà utilisé', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'code': 'EMAIL_ALREADY_USED',
            'message': 'Cet email est déjà utilisé',
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(client: mockClient, baseUrl: baseUrl);

      expect(
        () => service.register(
          email: 'existant@univ.fr',
          password: 'Password123!',
          termsAccepted: true,
        ),
        throwsA(
          isA<AuthException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.errorCode, 'errorCode', 'EMAIL_ALREADY_USED'),
        ),
      );
    });
  });

  group('AuthApiService.verifyEmail', () {
    test('Valide l’email avec le code à 6 chiffres (200 OK)', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/auth/verify-email');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['code'], '123456');

        return http.Response(
          jsonEncode({
            'emailVerified': true,
            'message': 'Email validé avec succès.',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(client: mockClient, baseUrl: baseUrl);
      final result = await service.verifyEmail(
        email: 'etudiant@univ.fr',
        code: '123456',
      );

      expect(result, 'Email validé avec succès.');
    });

    test('Lève AuthException si code invalide ou expiré (400)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Code de vérification invalide ou expiré'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(client: mockClient, baseUrl: baseUrl);

      expect(
        () => service.verifyEmail(email: 'etudiant@univ.fr', code: '000000'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('invalide'),
          ),
        ),
      );
    });
  });

  group('AuthApiService.login', () {
    test('Retourne une session active en cas de succès (200 OK) avec format plat', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/auth/login');
        return http.Response(
          jsonEncode({
            'accessToken': 'jwt-sample-token',
            'tokenType': 'Bearer',
            'userId': 1,
            'email': 'etudiant@univ.fr',
            'emailVerified': true,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(client: mockClient, baseUrl: baseUrl);
      final session = await service.login(
        email: 'etudiant@univ.fr',
        password: 'Password123!',
      );

      expect(session.accessToken, 'jwt-sample-token');
      expect(session.user.userId, 1);
      expect(session.user.emailVerified, isTrue);
    });

    test('Lève AuthException avec code 403 si email non vérifié', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message':
                'Veuillez valider votre adresse email avant de vous connecter',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(client: mockClient, baseUrl: baseUrl);

      expect(
        () => service.login(
          email: 'unverified@univ.fr',
          password: 'Password123!',
        ),
        throwsA(
          isA<AuthException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });
}
