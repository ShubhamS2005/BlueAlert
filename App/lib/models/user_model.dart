class User {
  final String id;
  final String firstname;
  final String lastname;
  final String email;
  final String phone;
  final String role;
  final String avatarUrl;
  final int credibilityScore;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.role,
    required this.avatarUrl,
    required this.credibilityScore,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      avatarUrl: json['userAvatar']['url'],
      credibilityScore: json['credibilityScore'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'phone': phone,
      'role': role,
      'userAvatar': {'url': avatarUrl},
      'credibilityScore': credibilityScore,
    };
  }
}