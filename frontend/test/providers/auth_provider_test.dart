import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trill_covoit/providers/auth_provider.dart';
import 'package:trill_covoit/services/api_client.dart';
import 'package:trill_covoit/services/auth_api_service.dart';

void main() {
  group('AuthProvider', () {
    test('État initial correct', () {
      final apiClient = ApiClient(client: MockClient((_) async => http.Response('{}', 200)), baseUrl: 'http://test.local');
      final service = AuthApiService(apiClient: apiClient);
      final provider = AuthProvider(apiService: service);

      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentSession, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.successMessage, isNull);
      expect(provider.fieldErrors, isNull);
      expect(provider.pendingVerificationEmail, isNull);
    });

    test('register réussit et met à jour pendingVerificationEmail', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Compte créé avec succès'}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test.local');
      final service = AuthApiService(apiClient: apiClient);
      final provider = AuthProvider(apiService: service);

      final success = await provider.register(
        email: 'nouveau@univ.fr',
        password: 'Password123!',
        termsAccepted: true,
      );

      expect(success, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.pendingVerificationEmail, 'nouveau@univ.fr');
      expect(provider.successMessage, contains('succès'));
      expect(provider.errorMessage, isNull);
      expect(provider.fieldErrors, isNull);
    });

    test('register échoue et conserve errorMessage et fieldErrors', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Données invalides',
            'fieldErrors': {'email': 'Email invalide', 'password': 'Trop court'},
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test.local');
      final service = AuthApiService(apiClient: apiClient);
      final provider = AuthProvider(apiService: service);

      final success = await provider.register(
        email: 'existant@univ.fr',
        password: 'pass',
        termsAccepted: true,
      );

      expect(success, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, 'Données invalides');
      expect(provider.fieldErrors?['email'], 'Email invalide');
      expect(provider.fieldErrors?['password'], 'Trop court');
    });

    test('verifyEmail réussit et met à jour successMessage', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Email validé avec succès'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test.local');
      final service = AuthApiService(apiClient: apiClient);
      final provider = AuthProvider(apiService: service);

      final success = await provider.verifyEmail(
        email: 'test@univ.fr',
        code: '123456',
      );

      expect(success, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.successMessage, contains('validé'));
      expect(provider.errorMessage, isNull);
    });

    test('verifyEmail échoue et conserve le message d\'erreur', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Code invalide'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test.local');
      final service = AuthApiService(apiClient: apiClient);
      final provider = AuthProvider(apiService: service);

      final success = await provider.verifyEmail(
        email: 'test@univ.fr',
        code: '999999',
      );

      expect(success, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, 'Code invalide');
    });

    test('login réussit et établit la session', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'accessToken': 'token-abc',
            'tokenType': 'Bearer',
            'userId': 99,
            'email': 'connecte@univ.fr',
            'emailVerified': true,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test.local');
      final service = AuthApiService(apiClient: apiClient);
      final provider = AuthProvider(apiService: service);

      final success = await provider.login(
        email: 'connecte@univ.fr',
        password: 'Password123!',
      );

      expect(success, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentSession?.user.email, 'connecte@univ.fr');
    });

    test('login avec email non vérifié (403) mémorise pendingVerificationEmail', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Veuillez vérifier votre email'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test.local');
      final service = AuthApiService(apiClient: apiClient);
      final provider = AuthProvider(apiService: service);

      final success = await provider.login(
        email: 'attente@univ.fr',
        password: 'Password123!',
      );

      expect(success, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.pendingVerificationEmail, 'attente@univ.fr');
      expect(provider.errorMessage, contains('vérifier'));
    });

    test('logout efface la session, messages et fieldErrors', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'accessToken': 'token-xyz',
            'tokenType': 'Bearer',
            'userId': 1,
            'email': 'a@univ.fr',
            'emailVerified': true,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test.local');
      final service = AuthApiService(apiClient: apiClient);
      final provider = AuthProvider(apiService: service);

      await provider.login(email: 'a@univ.fr', password: 'Password123!');
      expect(provider.isAuthenticated, isTrue);

      provider.logout();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentSession, isNull);
      expect(provider.errorMessage, isNull);
      expect(provider.successMessage, isNull);
      expect(provider.fieldErrors, isNull);
      expect(provider.pendingVerificationEmail, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('efface les messages précédents avant de passer isLoading à true', () async {
      final completer = Completer<http.Response>();
      final mockClient = MockClient((_) => completer.future);

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test.local');
      final service = AuthApiService(apiClient: apiClient);
      final provider = AuthProvider(apiService: service);

      provider.setPendingVerificationEmail('old@univ.fr');

      bool? loadingDuringFirstNotification;
      String? errorDuringFirstNotification;

      provider.addListener(() {
        if (loadingDuringFirstNotification == null && provider.isLoading) {
          loadingDuringFirstNotification = provider.isLoading;
          errorDuringFirstNotification = provider.errorMessage;
        }
      });

      final future = provider.login(email: 'test@univ.fr', password: 'Password123!');

      expect(loadingDuringFirstNotification, isTrue);
      expect(errorDuringFirstNotification, isNull);

      completer.complete(
        http.Response(
          jsonEncode({
            'accessToken': 'token-123',
            'tokenType': 'Bearer',
            'userId': 1,
            'email': 'test@univ.fr',
            'emailVerified': true,
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      await future;
      expect(provider.isLoading, isFalse);
    });

    test('bloque les opérations simultanées tant qu\'une requête est en cours', () async {
      final completer = Completer<http.Response>();
      final mockClient = MockClient((_) => completer.future);

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test.local');
      final service = AuthApiService(apiClient: apiClient);
      final provider = AuthProvider(apiService: service);

      final firstCall = provider.login(email: 'first@univ.fr', password: 'Password123!');
      expect(provider.isLoading, isTrue);

      final secondCallResult = await provider.login(email: 'second@univ.fr', password: 'Password123!');
      expect(secondCallResult, isFalse);

      final registerCallResult = await provider.register(
        email: 'third@univ.fr',
        password: 'Password123!',
        termsAccepted: true,
      );
      expect(registerCallResult, isFalse);

      completer.complete(
        http.Response(
          jsonEncode({
            'accessToken': 'token-1',
            'tokenType': 'Bearer',
            'userId': 1,
            'email': 'first@univ.fr',
            'emailVerified': true,
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      await firstCall;
      expect(provider.isLoading, isFalse);
      expect(provider.currentSession?.user.email, 'first@univ.fr');
    });

    test('ignore la réponse d\'une requête résolue après un logout()', () async {
      final completer = Completer<http.Response>();
      final mockClient = MockClient((_) => completer.future);

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test.local');
      final service = AuthApiService(apiClient: apiClient);
      final provider = AuthProvider(apiService: service);

      final loginFuture = provider.login(email: 'login@univ.fr', password: 'Password123!');
      expect(provider.isLoading, isTrue);

      provider.logout();
      expect(provider.isLoading, isFalse);
      expect(provider.currentSession, isNull);

      completer.complete(
        http.Response(
          jsonEncode({
            'accessToken': 'stale-token',
            'tokenType': 'Bearer',
            'userId': 42,
            'email': 'login@univ.fr',
            'emailVerified': true,
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final result = await loginFuture;
      expect(result, isFalse);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentSession, isNull);
      expect(provider.isLoading, isFalse);
    });
  });
}

