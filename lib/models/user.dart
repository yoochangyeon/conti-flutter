class UserResponse {
  final int id;
  final String email;
  final String name;
  final String? profileImage;

  UserResponse({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      profileImage: json['profileImage'] as String?,
    );
  }
}

class UserUpdateRequest {
  final String name;
  final String? profileImage;

  UserUpdateRequest({required this.name, this.profileImage});

  Map<String, dynamic> toJson() => {
    'name': name,
    if (profileImage != null) 'profileImage': profileImage,
  };
}

class UserTeamResponse {
  final int teamId;
  final String teamName;
  final String role;
  final DateTime joinedAt;

  UserTeamResponse({
    required this.teamId,
    required this.teamName,
    required this.role,
    required this.joinedAt,
  });

  factory UserTeamResponse.fromJson(Map<String, dynamic> json) {
    return UserTeamResponse(
      teamId: json['teamId'] as int,
      teamName: json['teamName'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  bool get isAdmin => role == 'ADMIN';
}

class TokenResponse {
  final String accessToken;
  final String refreshToken;

  TokenResponse({required this.accessToken, required this.refreshToken});

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
