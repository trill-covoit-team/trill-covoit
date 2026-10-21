import 'package:flutter_test/flutter_test.dart';
import 'package:trill_covoit/exceptions/api_exception.dart';
import 'package:trill_covoit/exceptions/auth_exception.dart';
import 'package:trill_covoit/models/auth_session.dart';
import 'package:trill_covoit/models/user.dart';

void main() {
  group('User', () {
    test('Désérialise correctement un utilisateur valide', () {
      final json = {
        'userId': 42,
        'email': 'etudiant@univ.fr',
        'emailVerified': true,
        'firstName': 'Jean',
        'lastName': 'Dupont',
      };

      final user = User.fromJson(json);

      expect(user.userId, 42);
      expect(user.email, 'etudiant@univ.fr');
      expect(user.emailVerified, isTrue);
      expect(user.firstName, 'Jean');
      expect(user.lastName, 'Dupont');
    });

    test('Rejette un JSON sans userId ou invalide', () {
      expect(
        () => User.fromJson({
          'email': 'test@univ.fr',
          'emailVerified': true,
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => User.fromJson({
          'userId': 'invalid_id',
          'email': 'test@univ.fr',
          'emailVerified': true,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('Rejette un JSON sans email ou vide', () {
      expect(
        () => User.fromJson({
          'userId': 1,
          'emailVerified': true,
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => User.fromJson({
          'userId': 1,
          'email': '   ',
          'emailVerified': true,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('Rejette un JSON sans emailVerified ou non booléen', () {
      expect(
        () => User.fromJson({
          'userId': 1,
          'email': 'test@univ.fr',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => User.fromJson({
          'userId': 1,
          'email': 'test@univ.fr',
          'emailVerified': 'yes',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('Sérialise vers un Map JSON valide', () {
      const user = User(
        userId: 1,
        email: 'test@univ.fr',
        emailVerified: true,
        firstName: 'Alice',
      );

      final map = user.toJson();

      expect(map['userId'], 1);
      expect(map['email'], 'test@univ.fr');
      expect(map['emailVerified'], isTrue);
      expect(map['firstName'], 'Alice');
      expect(map.containsKey('lastName'), isFalse);
    });
  });

  group('AuthSession', () {
    test('Désérialise depuis une réponse plate contenant token et utilisateur', () {
      final json = {
        'accessToken': 'jwt-token-123',
        'tokenType': 'Bearer',
        'userId': 5,
        'email': 'session@univ.fr',
        'emailVerified': true,
        'firstName': 'Marie',
      };

      final session = AuthSession.fromJson(json);

      expect(session.accessToken, 'jwt-token-123');
      expect(session.tokenType, 'Bearer');
      expect(session.user.userId, 5);
      expect(session.user.email, 'session@univ.fr');
      expect(session.user.firstName, 'Marie');
      expect(session.isAuthenticated, isTrue);
    });

    test('Rejette un JSON avec accessToken manquant ou vide', () {
      expect(
        () => AuthSession.fromJson({
          'userId': 10,
          'email': 'flat@univ.fr',
          'emailVerified': true,
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => AuthSession.fromJson({
          'accessToken': '   ',
          'userId': 10,
          'email': 'flat@univ.fr',
          'emailVerified': true,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Exceptions', () {
    test('ApiException contient le message, le status code et le code d\'erreur', () {
      const ex = ApiException(
        message: 'Erreur réseau',
        statusCode: 503,
        errorCode: 'SERVICE_UNAVAILABLE',
      );

      expect(ex.toString(), 'Erreur réseau');
      expect(ex.statusCode, 503);
      expect(ex.errorCode, 'SERVICE_UNAVAILABLE');
    });

    test('AuthException hérite de ApiException', () {
      const ex = AuthException(
        message: 'Identifiants invalides',
        statusCode: 401,
        errorCode: 'INVALID_CREDENTIALS',
      );

      expect(ex, isA<ApiException>());
      expect(ex.statusCode, 401);
      expect(ex.errorCode, 'INVALID_CREDENTIALS');
    });
  });
}
