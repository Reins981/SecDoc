class UserInstance {
  final String uid;
  final String email;
  final String domain;
  final String? userName;
  final String role;
  final bool disabled;
  final bool verified;

  UserInstance({
    required this.uid,
    required this.email,
    required this.domain,
    required this.userName,
    required this.role,
    required this.disabled,
    required this.verified});

  factory UserInstance.fromJson(Map<String, dynamic> json) {
    return UserInstance(
      uid: json['uid'],
      email: json['email'],
      domain: json['customClaims']['domain'],
      userName: json['display_name'] ?? json['email'],
      role: json['customClaims']['role'],
      disabled: json['customClaims']['disabled'],
      verified: json['customClaims']['verified']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'domain': domain,
      'userName': userName,
      'role': role,
      'disabled': disabled,
      'verified': verified,
    };
  }
}
