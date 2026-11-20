import 'package:trill_covoit/models/user.dart';

class AuthSession {
  final String accessToken;
  final String tokenType;
  final User user;

  const AuthSession({
    required this.accessToken,
    this.tokenType = 'Bearer',
    required this.user,
  });

  bool get isAuthenticated => accessToken.isNotEmpty;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'];
    if (token is! String || token.trim().isEmpty) {
      throw const FormatException('Token d\'accès absent ou invalide.');
    }

    return AuthSession(
      accessToken: token,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      user: User.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'tokenType': tokenType,
      ...user.toJson(),
    };
  }
}
