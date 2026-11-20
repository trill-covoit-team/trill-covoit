import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trill_covoit/exceptions/api_exception.dart';
import 'package:trill_covoit/services/api_client.dart';
import 'package:trill_covoit/services/auth_api_service.dart';

void main() {
  const baseUrl = 'http://test.local/api';

  AuthApiService createService(MockClientHandler handler) {
    final client = MockClient(handler);
    final apiClient = ApiClient(client: client, baseUrl: baseUrl);
    return AuthApiService(apiClient: apiClient);
  }

  group('AuthApiService.register', () {
    test('Retourne le message en cas de succès (201 Created)', () async {
      final service = createService((request) async {
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

      final result = await service.register(
        email: 'etudiant@univ-tlse3.fr',
        password: 'Password123!',
        termsAccepted: true,
      );

      expect(result, contains('Votre compte a été créé'));
    });

    test('Lève ApiException avec code 409 et message backend si email déjà utilisé', () async {
      final service = createService((request) async {
        return http.Response(
          jsonEncode({
            'code': 'EMAIL_ALREADY_USED',
            'message': 'Cette adresse email est déjà utilisée.',
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => service.register(
          email: 'existant@univ-tlse3.fr',
          password: 'Password123!',
          termsAccepted: true,
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.errorCode, 'errorCode', 'EMAIL_ALREADY_USED')
              .having((e) => e.message, 'message', 'Cette adresse email est déjà utilisée.'),
        ),
      );
    });
  });

  group('AuthApiService.verifyEmail', () {
    test('Retourne le message de confirmation en cas de succès', () async {
      final service = createService((request) async {
        expect(request.url.toString(), '$baseUrl/auth/verify-email');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['email'], 'etudiant@univ-tlse3.fr');
        expect(payload['code'], '123456');

        return http.Response(
          jsonEncode({
            'message': 'Votre adresse email a été validée avec succès.',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await service.verifyEmail(
        email: 'etudiant@univ-tlse3.fr',
        code: '123456',
      );

      expect(result, contains('validée avec succès'));
    });

    test('Lève ApiException avec code 400 si le code est invalide ou expiré', () async {
      final service = createService((request) async {
        return http.Response(
          jsonEncode({
            'code': 'INVALID_VERIFICATION_CODE',
            'message': 'Le code de validation est invalide ou expiré.',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => service.verifyEmail(
          email: 'etudiant@univ-tlse3.fr',
          code: '000000',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.errorCode, 'errorCode', 'INVALID_VERIFICATION_CODE')
              .having((e) => e.message, 'message', 'Le code de validation est invalide ou expiré.'),
        ),
      );
    });
  });

  group('AuthApiService.login', () {
    test('Retourne une AuthSession avec token et utilisateur en cas de succès', () async {
      final service = createService((request) async {
        expect(request.url.toString(), '$baseUrl/auth/login');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['email'], 'etudiant@univ-tlse3.fr');
        expect(payload['password'], 'Password123!');

        return http.Response(
          jsonEncode({
            'userId': 1,
            'email': 'etudiant@univ-tlse3.fr',
            'emailVerified': true,
            'firstName': 'Camille',
            'lastName': 'Martin',
            'accessToken': 'jwt-sample-token',
            'tokenType': 'Bearer',
            'message': 'Connexion réussie.',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final session = await service.login(
        email: 'etudiant@univ-tlse3.fr',
        password: 'Password123!',
      );

      expect(session.accessToken, 'jwt-sample-token');
      expect(session.tokenType, 'Bearer');
      expect(session.user.userId, 1);
      expect(session.user.email, 'etudiant@univ-tlse3.fr');
      expect(session.user.emailVerified, isTrue);
      expect(session.user.firstName, 'Camille');
      expect(session.user.lastName, 'Martin');
    });

    test('Lève ApiException avec code 401 si identifiants invalides', () async {
      final service = createService((request) async {
        return http.Response(
          jsonEncode({
            'code': 'INVALID_CREDENTIALS',
            'message': 'L\'adresse email ou le mot de passe est incorrect.',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => service.login(
          email: 'etudiant@univ-tlse3.fr',
          password: 'MauvaisMotDePasse',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.errorCode, 'errorCode', 'INVALID_CREDENTIALS'),
        ),
      );
    });

    test('Lève ApiException avec code 403 si email non vérifié', () async {
      final service = createService((request) async {
        return http.Response(
          jsonEncode({
            'code': 'EMAIL_NOT_VERIFIED',
            'message': 'Veuillez valider votre adresse email avant de vous connecter.',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => service.login(
          email: 'non-verifie@univ-tlse3.fr',
          password: 'Password123!',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.errorCode, 'errorCode', 'EMAIL_NOT_VERIFIED'),
        ),
      );
    });
  });
}
