class User {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String role;
  final String provider;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    required this.provider,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
      role: json['role'],
      provider: json['provider'],
    );
  }
}
