import 'package:flutter_test/flutter_test.dart';
import 'package:trill_covoit/features/auth/models/auth_exception.dart';
import 'package:trill_covoit/features/auth/models/auth_session.dart';
import 'package:trill_covoit/features/auth/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('Désérialise correctement avec la clé "userId"', () {
      final json = {
        'userId': 42,
        'email': 'etudiant@univ.fr',
        'emailVerified': true,
        'firstName': 'Jean',
        'lastName': 'Dupont',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 42);
      expect(user.email, 'etudiant@univ.fr');
      expect(user.emailVerified, isTrue);
      expect(user.firstName, 'Jean');
      expect(user.lastName, 'Dupont');
    });

    test('Désérialise correctement avec la clé "id"', () {
      final json = {
        'id': 7,
        'email': 'test@univ.fr',
        'emailVerified': false,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 7);
      expect(user.email, 'test@univ.fr');
      expect(user.emailVerified, isFalse);
      expect(user.firstName, isNull);
    });

    test('Sérialise vers un Map JSON valide', () {
      const user = UserModel(
        id: 1,
        email: 'test@univ.fr',
        emailVerified: true,
        firstName: 'Alice',
      );

      final map = user.toJson();

      expect(map['id'], 1);
      expect(map['email'], 'test@univ.fr');
      expect(map['emailVerified'], isTrue);
      expect(map['firstName'], 'Alice');
      expect(map.containsKey('lastName'), isFalse);
    });
  });

  group('AuthSession', () {
    test('Désérialise avec objet user imbriqué', () {
      final json = {
        'accessToken': 'jwt-token-123',
        'tokenType': 'Bearer',
        'user': {
          'userId': 5,
          'email': 'session@univ.fr',
          'emailVerified': true,
        },
      };

      final session = AuthSession.fromJson(json);

      expect(session.accessToken, 'jwt-token-123');
      expect(session.tokenType, 'Bearer');
      expect(session.user.id, 5);
      expect(session.user.email, 'session@univ.fr');
    });

    test('Désérialise depuis une réponse plate', () {
      final json = {
        'id': 10,
        'email': 'flat@univ.fr',
        'emailVerified': true,
      };

      final session = AuthSession.fromJson(json);

      expect(session.user.id, 10);
      expect(session.user.email, 'flat@univ.fr');
      expect(session.accessToken, isNull);
    });
  });

  group('AuthException', () {
    test('Contient le message, le status code et le code d\'erreur', () {
      const ex = AuthException(
        message: 'Erreur d’accès',
        statusCode: 403,
        errorCode: 'EMAIL_NOT_VERIFIED',
      );

      expect(ex.toString(), 'Erreur d’accès');
      expect(ex.statusCode, 403);
      expect(ex.errorCode, 'EMAIL_NOT_VERIFIED');
    });
  });
}
