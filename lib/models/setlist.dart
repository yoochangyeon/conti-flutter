export 'setlist_template.dart';

class SetlistResponse {
  final int id;
  final String? title;
  final DateTime worshipDate;
  final String? worshipType;
  final String? worshipTypeDisplayName;
  final int? leaderId;
  final int songCount;
  final DateTime createdAt;
  final String? setlistType;
  final String? setlistTypeDisplayName;
  final int? contiId;

  SetlistResponse({
    required this.id,
    this.title,
    required this.worshipDate,
    this.worshipType,
    this.worshipTypeDisplayName,
    this.leaderId,
    required this.songCount,
    required this.createdAt,
    this.setlistType,
    this.setlistTypeDisplayName,
    this.contiId,
  });

  factory SetlistResponse.fromJson(Map<String, dynamic> json) {
    return SetlistResponse(
      id: json['id'] as int,
      title: json['title'] as String?,
      worshipDate: DateTime.parse(json['worshipDate'] as String),
      worshipType: json['worshipType'] as String?,
      worshipTypeDisplayName: json['worshipTypeDisplayName'] as String?,
      leaderId: json['leaderId'] as int?,
      songCount: json['songCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      setlistType: json['setlistType'] as String?,
      setlistTypeDisplayName: json['setlistTypeDisplayName'] as String?,
      contiId: json['contiId'] as int?,
    );
  }

  bool get isConti => setlistType == 'CONTI';
  bool get isCueSheet => setlistType == 'CUE_SHEET' || setlistType == null;

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    return worshipTypeDisplayName ?? worshipType ?? '예배';
  }
}

class SetlistDetailResponse {
  final int id;
  final String? title;
  final DateTime worshipDate;
  final String? worshipType;
  final String? worshipTypeDisplayName;
  final int? leaderId;
  final int songCount;
  final DateTime createdAt;
  final String? memo;
  final int? creatorId;
  final List<SetlistItemResponse> items;
  final String? setlistType;
  final String? setlistTypeDisplayName;
  final int? contiId;

  SetlistDetailResponse({
    required this.id,
    this.title,
    required this.worshipDate,
    this.worshipType,
    this.worshipTypeDisplayName,
    this.leaderId,
    required this.songCount,
    required this.createdAt,
    this.memo,
    this.creatorId,
    required this.items,
    this.setlistType,
    this.setlistTypeDisplayName,
    this.contiId,
  });

  factory SetlistDetailResponse.fromJson(Map<String, dynamic> json) {
    return SetlistDetailResponse(
      id: json['id'] as int,
      title: json['title'] as String?,
      worshipDate: DateTime.parse(json['worshipDate'] as String),
      worshipType: json['worshipType'] as String?,
      worshipTypeDisplayName: json['worshipTypeDisplayName'] as String?,
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
      setlistType: json['setlistType'] as String?,
      setlistTypeDisplayName: json['setlistTypeDisplayName'] as String?,
      contiId: json['contiId'] as int?,
    );
  }

  bool get isConti => setlistType == 'CONTI';
  bool get isCueSheet => setlistType == 'CUE_SHEET' || setlistType == null;

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    return worshipTypeDisplayName ?? worshipType ?? '예배';
  }
}

class SetlistItemResponse {
  final int id;
  final int? songId;
  final String songTitle;
  final String? artist;
  final int orderIndex;
  final String? songKey;
  final String? memo;
  final String? itemType;
  final String? itemTypeDisplayName;
  final int? durationMinutes;
  final String? color;
  final String? servicePhase;
  final String? servicePhaseDisplayName;

  SetlistItemResponse({
    required this.id,
    this.songId,
    required this.songTitle,
    this.artist,
    required this.orderIndex,
    this.songKey,
    this.memo,
    this.itemType,
    this.itemTypeDisplayName,
    this.durationMinutes,
    this.color,
    this.servicePhase,
    this.servicePhaseDisplayName,
  });

  factory SetlistItemResponse.fromJson(Map<String, dynamic> json) {
    return SetlistItemResponse(
      id: json['id'] as int,
      songId: json['songId'] as int?,
      songTitle: json['songTitle'] as String? ?? json['title'] as String? ?? '',
      artist: json['artist'] as String?,
      orderIndex: json['orderIndex'] as int,
      songKey: json['songKey'] as String?,
      memo: json['memo'] as String?,
      itemType: json['itemType'] as String?,
      itemTypeDisplayName: json['itemTypeDisplayName'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      color: json['color'] as String?,
      servicePhase: json['servicePhase'] as String?,
      servicePhaseDisplayName: json['servicePhaseDisplayName'] as String?,
    );
  }

  bool get isSongItem => itemType == null || itemType == 'SONG';
  bool get isHeader => itemType == 'HEADER';
}

class SetlistCreateRequest {
  final String? title;
  final DateTime worshipDate;
  final String? worshipType;
  final int? leaderId;
  final String? memo;
  final String? setlistType;

  SetlistCreateRequest({
    this.title,
    required this.worshipDate,
    this.worshipType,
    this.leaderId,
    this.memo,
    this.setlistType,
  });

  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title,
    'worshipDate': worshipDate.toIso8601String().split('T')[0],
    if (worshipType != null) 'worshipType': worshipType,
    if (leaderId != null) 'leaderId': leaderId,
    if (memo != null) 'memo': memo,
    if (setlistType != null) 'setlistType': setlistType,
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
  final int? songId;
  final String? songKey;
  final String? memo;
  final String? itemType;
  final String? title;
  final int? durationMinutes;
  final String? color;
  final String? servicePhase;

  SetlistItemRequest({
    this.songId,
    this.songKey,
    this.memo,
    this.itemType,
    this.title,
    this.durationMinutes,
    this.color,
    this.servicePhase,
  });

  Map<String, dynamic> toJson() => {
    if (songId != null) 'songId': songId,
    if (songKey != null) 'songKey': songKey,
    if (memo != null) 'memo': memo,
    if (itemType != null) 'itemType': itemType,
    if (title != null) 'title': title,
    if (durationMinutes != null) 'durationMinutes': durationMinutes,
    if (color != null) 'color': color,
    if (servicePhase != null) 'servicePhase': servicePhase,
  };
}

class SetlistCopyRequest {
  final String? title;
  final DateTime worshipDate;
  final String? worshipType;

  SetlistCopyRequest({
    this.title,
    required this.worshipDate,
    this.worshipType,
  });

  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title,
    'worshipDate': worshipDate.toIso8601String().split('T')[0],
    if (worshipType != null) 'worshipType': worshipType,
  };
}
