class User {
  final String id;
  final String firstname;
  final String lastname;
  final String email;
  final String phone;
  final String role;
  final String avatarUrl;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.role,
    required this.avatarUrl,
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
    };
  }
}