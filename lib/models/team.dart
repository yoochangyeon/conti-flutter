class TeamResponse {
  final int id;
  final String name;
  final String? description;
  final String inviteCode;
  final DateTime createdAt;

  TeamResponse({
    required this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    required this.createdAt,
  });

  factory TeamResponse.fromJson(Map<String, dynamic> json) {
    return TeamResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      inviteCode: json['inviteCode'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class TeamMemberResponse {
  final int memberId;
  final int userId;
  final String userName;
  final String? profileImage;
  final String role;
  final DateTime joinedAt;

  TeamMemberResponse({
    required this.memberId,
    required this.userId,
    required this.userName,
    this.profileImage,
    required this.role,
    required this.joinedAt,
  });

  factory TeamMemberResponse.fromJson(Map<String, dynamic> json) {
    return TeamMemberResponse(
      memberId: json['memberId'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      profileImage: json['profileImage'] as String?,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  bool get isAdmin => role == 'ADMIN';
}

class TeamCreateRequest {
  final String name;
  final String? description;

  TeamCreateRequest({required this.name, this.description});

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
  };
}

class TeamUpdateRequest {
  final String? name;
  final String? description;

  TeamUpdateRequest({this.name, this.description});

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (description != null) 'description': description,
  };
}

class InviteResponse {
  final String inviteCode;

  InviteResponse({required this.inviteCode});

  factory InviteResponse.fromJson(Map<String, dynamic> json) {
    return InviteResponse(inviteCode: json['inviteCode'] as String);
  }
}
