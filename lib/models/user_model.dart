class UserModel {
  final String id;
  final String username;
  final String profileImageUrl;
  final bool login;
  final String? name;
  final String? pronouns;
  final String? bio;

  UserModel({
    required this.id,
    required this.username,
    required this.profileImageUrl,
    this.login = false,
    this.name,
    this.pronouns,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      profileImageUrl: json['profileImageUrl'] as String,
      login: json['login'] as bool? ?? false,
      name: json['name'] as String?,
      pronouns: json['pronouns'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'profileImageUrl': profileImageUrl,
    'login': login,
    'name': name,
    'pronouns': pronouns,
    'bio': bio,
  };
}
