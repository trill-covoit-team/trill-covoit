import 'package:flutter_test/flutter_test.dart';
import 'package:trill_covoit/exceptions/api_exception.dart';
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

    test('Rejette un JSON sans emailVerified booléen', () {
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
          'emailVerified': 'true',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('Gère les champs optionnels absents', () {
      final user = User.fromJson({
        'userId': 1,
        'email': 'minimal@univ.fr',
        'emailVerified': false,
      });

      expect(user.firstName, isNull);
      expect(user.lastName, isNull);
    });

    test('Sérialise vers un Map JSON valide', () {
      const user = User(
        userId: 10,
        email: 'test@univ.fr',
        emailVerified: true,
        firstName: 'Alice',
      );

      final map = user.toJson();
      expect(map['userId'], 10);
      expect(map['email'], 'test@univ.fr');
      expect(map['emailVerified'], isTrue);
      expect(map['firstName'], 'Alice');
      expect(map.containsKey('lastName'), isFalse);
    });
  });

  group('AuthSession', () {
    test('Désérialise correctement une session valide avec utilisateur à la racine', () {
      final json = {
        'accessToken': 'jwt-token-123',
        'tokenType': 'Bearer',
        'userId': 5,
        'email': 'user@univ.fr',
        'emailVerified': true,
        'firstName': 'Bob',
      };

      final session = AuthSession.fromJson(json);

      expect(session.accessToken, 'jwt-token-123');
      expect(session.tokenType, 'Bearer');
      expect(session.user.userId, 5);
      expect(session.user.email, 'user@univ.fr');
      expect(session.user.emailVerified, isTrue);
      expect(session.user.firstName, 'Bob');
    });

    test('Rejette un JSON avec accessToken manquant ou vide', () {
      expect(
        () => AuthSession.fromJson({
          'tokenType': 'Bearer',
          'userId': 1,
          'email': 'a@univ.fr',
          'emailVerified': true,
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => AuthSession.fromJson({
          'accessToken': '   ',
          'tokenType': 'Bearer',
          'userId': 1,
          'email': 'a@univ.fr',
          'emailVerified': true,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ApiException', () {
    test('ApiException contient message, statusCode optionnel, code d\'erreur et fieldErrors', () {
      const ex = ApiException(
        message: 'Données invalides',
        statusCode: 400,
        errorCode: 'VALIDATION_ERROR',
        fieldErrors: {'email': 'Format invalide'},
      );

      expect(ex.toString(), 'Données invalides');
      expect(ex.statusCode, 400);
      expect(ex.errorCode, 'VALIDATION_ERROR');
      expect(ex.fieldErrors, {'email': 'Format invalide'});
    });

    test('ApiException supporte statusCode null pour les erreurs réseau', () {
      const ex = ApiException(
        message: 'Délai d\'attente expiré',
      );

      expect(ex.statusCode, isNull);
      expect(ex.errorCode, isNull);
      expect(ex.fieldErrors, isNull);
    });
  });
}
