import 'user_model.dart';

class AuthSession {
  final String? accessToken;
  final String tokenType;
  final UserModel user;

  const AuthSession({
    this.accessToken,
    this.tokenType = 'Bearer',
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    // Si la réponse imbrique 'user', on la récupère, sinon on lit à la racine
    final userData = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;

    return AuthSession(
      accessToken: json['accessToken'] as String?,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      user: UserModel.fromJson(userData),
    );
  }
}
