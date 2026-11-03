class User {
  final int userId;
  final String email;
  final bool emailVerified;
  final String? firstName;
  final String? lastName;

  const User({
    required this.userId,
    required this.email,
    required this.emailVerified,
    this.firstName,
    this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawId = json['userId'];
    final int? userId = rawId is int
        ? rawId
        : (rawId != null ? int.tryParse(rawId.toString()) : null);
    if (userId == null) {
      throw const FormatException('Champ "userId" manquant ou invalide.');
    }

    final rawEmail = json['email'];
    if (rawEmail is! String || rawEmail.trim().isEmpty) {
      throw const FormatException('Champ "email" manquant ou invalide.');
    }

    final rawVerified = json['emailVerified'];
    if (rawVerified is! bool) {
      throw const FormatException('Champ "emailVerified" manquant ou invalide.');
    }

    return User(
      userId: userId,
      email: rawEmail,
      emailVerified: rawVerified,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'emailVerified': emailVerified,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
    };
  }
}
