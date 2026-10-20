class UserModel {
  final int userId;
  final String email;
  final bool emailVerified;
  final String? firstName;
  final String? lastName;

  const UserModel({
    required this.userId,
    required this.email,
    this.emailVerified = false,
    this.firstName,
    this.lastName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['userId'] ?? 0;
    return UserModel(
      userId: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      email: json['email'] as String? ?? '',
      emailVerified: json['emailVerified'] as bool? ?? false,
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
