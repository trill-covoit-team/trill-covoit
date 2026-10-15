import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trill_covoit/features/auth/providers/auth_provider.dart';
import 'package:trill_covoit/features/auth/services/auth_api_service.dart';

void main() {
  group('AuthProvider', () {
    test('État initial correct', () {
      final provider = AuthProvider();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentSession, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.successMessage, isNull);
    });

    test('register réussit et met à jour pendingVerificationEmail', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Compte créé avec succès'}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(client: mockClient, baseUrl: 'http://test.local');
      final provider = AuthProvider(apiService: service);

      final success = await provider.register(
        email: 'nouveau@univ.fr',
        password: 'Password123!',
      );

      expect(success, isTrue);
      expect(provider.pendingVerificationEmail, 'nouveau@univ.fr');
      expect(provider.successMessage, contains('succès'));
      expect(provider.errorMessage, isNull);
    });

    test('register échoue et met à jour errorMessage', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Cet email est déjà utilisé'}),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(client: mockClient, baseUrl: 'http://test.local');
      final provider = AuthProvider(apiService: service);

      final success = await provider.register(
        email: 'existant@univ.fr',
        password: 'Password123!',
      );

      expect(success, isFalse);
      expect(provider.errorMessage, 'Cet email est déjà utilisé');
    });

    test('login réussit et établit la session', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'accessToken': 'token-abc',
            'user': {
              'userId': 99,
              'email': 'connecte@univ.fr',
              'emailVerified': true,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(client: mockClient, baseUrl: 'http://test.local');
      final provider = AuthProvider(apiService: service);

      final success = await provider.login(
        email: 'connecte@univ.fr',
        password: 'Password123!',
      );

      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentSession?.user.email, 'connecte@univ.fr');
    });

    test('logout efface la session en cours', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'user': {'userId': 1, 'email': 'a@univ.fr', 'emailVerified': true},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(client: mockClient, baseUrl: 'http://test.local');
      final provider = AuthProvider(apiService: service);

      await provider.login(email: 'a@univ.fr', password: 'Password123!');
      expect(provider.isAuthenticated, isTrue);

      provider.logout();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentSession, isNull);
    });
  });
}
