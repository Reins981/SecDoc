class UserInstance {
  final String uid;
  final String email;
  final String domain;
  final String role;

  UserInstance({required this.uid, required this.email, required this.domain, required this.role});

  factory UserInstance.fromJson(Map<String, dynamic> json) {
    return UserInstance(
      uid: json['uid'],
      email: json['email'],
      domain: json['customClaims']['domain'],
      role: json['customClaims']['role'],
    );
  }
}
