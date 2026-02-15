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
  final List<MemberPositionResponse> positions;

  TeamMemberResponse({
    required this.memberId,
    required this.userId,
    required this.userName,
    this.profileImage,
    required this.role,
    required this.joinedAt,
    this.positions = const [],
  });

  factory TeamMemberResponse.fromJson(Map<String, dynamic> json) {
    return TeamMemberResponse(
      memberId: json['memberId'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      profileImage: json['profileImage'] as String?,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      positions: (json['positions'] as List?)
              ?.map((e) =>
                  MemberPositionResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isEditor => role == 'EDITOR' || isAdmin;
  bool get isScheduler => role == 'SCHEDULER' || isEditor;
  bool get canEdit => isEditor;
  bool get canSchedule => isScheduler;

  String get roleDisplayName => switch (role) {
        'ADMIN' => '관리자',
        'EDITOR' => '편집자',
        'SCHEDULER' => '스케줄러',
        'VIEWER' => '뷰어',
        'GUEST' => '게스트',
        _ => role,
      };

  String? get primaryPositionDisplayName {
    final primary = positions.where((p) => p.isPrimary).toList();
    if (primary.isNotEmpty) return primary.first.displayName;
    if (positions.isNotEmpty) return positions.first.displayName;
    return null;
  }
}

class MemberPositionResponse {
  final int id;
  final String position;
  final String displayName;
  final bool isPrimary;

  MemberPositionResponse({
    required this.id,
    required this.position,
    required this.displayName,
    required this.isPrimary,
  });

  factory MemberPositionResponse.fromJson(Map<String, dynamic> json) {
    return MemberPositionResponse(
      id: json['id'] as int,
      position: json['position'] as String,
      displayName: json['displayName'] as String,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
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

// Team Notice
class TeamNoticeResponse {
  final int id;
  final int teamId;
  final int authorId;
  final String authorName;
  final String title;
  final String? content;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeamNoticeResponse({
    required this.id,
    required this.teamId,
    required this.authorId,
    required this.authorName,
    required this.title,
    this.content,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamNoticeResponse.fromJson(Map<String, dynamic> json) {
    return TeamNoticeResponse(
      id: json['id'] as int,
      teamId: json['teamId'] as int,
      authorId: json['authorId'] as int,
      authorName: json['authorName'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

// Setlist Note
class SetlistNoteResponse {
  final int id;
  final int setlistId;
  final int authorId;
  final String authorName;
  final String? position;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  SetlistNoteResponse({
    required this.id,
    required this.setlistId,
    required this.authorId,
    required this.authorName,
    this.position,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SetlistNoteResponse.fromJson(Map<String, dynamic> json) {
    return SetlistNoteResponse(
      id: json['id'] as int,
      setlistId: json['setlistId'] as int,
      authorId: json['authorId'] as int,
      authorName: json['authorName'] as String,
      position: json['position'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
