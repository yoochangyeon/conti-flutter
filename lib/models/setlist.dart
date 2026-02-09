class SetlistResponse {
  final int id;
  final String? title;
  final DateTime worshipDate;
  final String? worshipType;
  final int? leaderId;
  final int songCount;
  final DateTime createdAt;

  SetlistResponse({
    required this.id,
    this.title,
    required this.worshipDate,
    this.worshipType,
    this.leaderId,
    required this.songCount,
    required this.createdAt,
  });

  factory SetlistResponse.fromJson(Map<String, dynamic> json) {
    return SetlistResponse(
      id: json['id'] as int,
      title: json['title'] as String?,
      worshipDate: DateTime.parse(json['worshipDate'] as String),
      worshipType: json['worshipType'] as String?,
      leaderId: json['leaderId'] as int?,
      songCount: json['songCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    return worshipType ?? '예배';
  }
}

class SetlistDetailResponse {
  final int id;
  final String? title;
  final DateTime worshipDate;
  final String? worshipType;
  final int? leaderId;
  final int songCount;
  final DateTime createdAt;
  final String? memo;
  final int? creatorId;
  final List<SetlistItemResponse> items;

  SetlistDetailResponse({
    required this.id,
    this.title,
    required this.worshipDate,
    this.worshipType,
    this.leaderId,
    required this.songCount,
    required this.createdAt,
    this.memo,
    this.creatorId,
    required this.items,
  });

  factory SetlistDetailResponse.fromJson(Map<String, dynamic> json) {
    return SetlistDetailResponse(
      id: json['id'] as int,
      title: json['title'] as String?,
      worshipDate: DateTime.parse(json['worshipDate'] as String),
      worshipType: json['worshipType'] as String?,
      leaderId: json['leaderId'] as int?,
      songCount: json['songCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      memo: json['memo'] as String?,
      creatorId: json['creatorId'] as int?,
      items: (json['items'] as List?)
              ?.map((e) =>
                  SetlistItemResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    return worshipType ?? '예배';
  }
}

class SetlistItemResponse {
  final int id;
  final int songId;
  final String songTitle;
  final String? artist;
  final int orderIndex;
  final String? songKey;
  final String? memo;

  SetlistItemResponse({
    required this.id,
    required this.songId,
    required this.songTitle,
    this.artist,
    required this.orderIndex,
    this.songKey,
    this.memo,
  });

  factory SetlistItemResponse.fromJson(Map<String, dynamic> json) {
    return SetlistItemResponse(
      id: json['id'] as int,
      songId: json['songId'] as int,
      songTitle: json['songTitle'] as String,
      artist: json['artist'] as String?,
      orderIndex: json['orderIndex'] as int,
      songKey: json['songKey'] as String?,
      memo: json['memo'] as String?,
    );
  }
}

class SetlistCreateRequest {
  final String? title;
  final DateTime worshipDate;
  final String? worshipType;
  final int? leaderId;
  final String? memo;

  SetlistCreateRequest({
    this.title,
    required this.worshipDate,
    this.worshipType,
    this.leaderId,
    this.memo,
  });

  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title,
    'worshipDate': worshipDate.toIso8601String().split('T')[0],
    if (worshipType != null) 'worshipType': worshipType,
    if (leaderId != null) 'leaderId': leaderId,
    if (memo != null) 'memo': memo,
  };
}

class SetlistUpdateRequest {
  final String? title;
  final DateTime? worshipDate;
  final String? worshipType;
  final int? leaderId;
  final String? memo;

  SetlistUpdateRequest({
    this.title,
    this.worshipDate,
    this.worshipType,
    this.leaderId,
    this.memo,
  });

  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title,
    if (worshipDate != null)
      'worshipDate': worshipDate!.toIso8601String().split('T')[0],
    if (worshipType != null) 'worshipType': worshipType,
    if (leaderId != null) 'leaderId': leaderId,
    if (memo != null) 'memo': memo,
  };
}

class SetlistItemRequest {
  final int songId;
  final String? songKey;
  final String? memo;

  SetlistItemRequest({required this.songId, this.songKey, this.memo});

  Map<String, dynamic> toJson() => {
    'songId': songId,
    if (songKey != null) 'songKey': songKey,
    if (memo != null) 'memo': memo,
  };
}
