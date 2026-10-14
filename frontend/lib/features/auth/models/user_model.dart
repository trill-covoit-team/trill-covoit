class UserModel {
  final int id;
  final String email;
  final bool emailVerified;
  final String? firstName;
  final String? lastName;

  const UserModel({
    required this.id,
    required this.email,
    this.emailVerified = false,
    this.firstName,
    this.lastName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Accepte indifféremment userId ou id selon la réponse back
    final rawId = json['userId'] ?? json['id'] ?? 0;
    return UserModel(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      email: json['email'] as String? ?? '',
      emailVerified: json['emailVerified'] as bool? ?? false,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'emailVerified': emailVerified,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
    };
  }
}
