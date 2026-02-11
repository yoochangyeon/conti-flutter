class SongResponse {
  final int id;
  final String title;
  final String? artist;
  final String? originalKey;
  final int? bpm;
  final List<String> tags;
  final DateTime createdAt;

  SongResponse({
    required this.id,
    required this.title,
    this.artist,
    this.originalKey,
    this.bpm,
    required this.tags,
    required this.createdAt,
  });

  factory SongResponse.fromJson(Map<String, dynamic> json) {
    return SongResponse(
      id: json['id'] as int,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      originalKey: json['originalKey'] as String?,
      bpm: json['bpm'] as int?,
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SongDetailResponse {
  final int id;
  final String title;
  final String? artist;
  final String? originalKey;
  final int? bpm;
  final List<String> tags;
  final DateTime createdAt;
  final String? memo;
  final String? youtubeUrl;
  final String? musicUrl;
  final List<SongFileResponse> files;
  final int usageCount;
  final List<SongSectionResponse> sections;

  SongDetailResponse({
    required this.id,
    required this.title,
    this.artist,
    this.originalKey,
    this.bpm,
    required this.tags,
    required this.createdAt,
    this.memo,
    this.youtubeUrl,
    this.musicUrl,
    required this.files,
    required this.usageCount,
    required this.sections,
  });

  factory SongDetailResponse.fromJson(Map<String, dynamic> json) {
    return SongDetailResponse(
      id: json['id'] as int,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      originalKey: json['originalKey'] as String?,
      bpm: json['bpm'] as int?,
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      memo: json['memo'] as String?,
      youtubeUrl: json['youtubeUrl'] as String?,
      musicUrl: json['musicUrl'] as String?,
      files: (json['files'] as List?)
              ?.map((e) => SongFileResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      usageCount: json['usageCount'] as int? ?? 0,
      sections: (json['sections'] as List?)
              ?.map((e) =>
                  SongSectionResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SongSectionResponse {
  final int id;
  final String sectionType;
  final int orderIndex;
  final String? label;
  final String? chords;
  final int? buildUpLevel;
  final String? memo;

  SongSectionResponse({
    required this.id,
    required this.sectionType,
    required this.orderIndex,
    this.label,
    this.chords,
    this.buildUpLevel,
    this.memo,
  });

  factory SongSectionResponse.fromJson(Map<String, dynamic> json) {
    return SongSectionResponse(
      id: json['id'] as int,
      sectionType: json['sectionType'] as String,
      orderIndex: json['orderIndex'] as int,
      label: json['label'] as String?,
      chords: json['chords'] as String?,
      buildUpLevel: json['buildUpLevel'] as int?,
      memo: json['memo'] as String?,
    );
  }
}

class SongSectionRequest {
  final String sectionType;
  final int orderIndex;
  final String? label;
  final String? chords;
  final int? buildUpLevel;
  final String? memo;

  SongSectionRequest({
    required this.sectionType,
    required this.orderIndex,
    this.label,
    this.chords,
    this.buildUpLevel,
    this.memo,
  });

  Map<String, dynamic> toJson() => {
        'sectionType': sectionType,
        'orderIndex': orderIndex,
        if (label != null) 'label': label,
        if (chords != null) 'chords': chords,
        if (buildUpLevel != null) 'buildUpLevel': buildUpLevel,
        if (memo != null) 'memo': memo,
      };
}

class SongFileResponse {
  final int id;
  final String fileName;
  final String fileUrl;
  final String? fileType;
  final int? fileSize;
  final DateTime createdAt;

  SongFileResponse({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    this.fileType,
    this.fileSize,
    required this.createdAt,
  });

  factory SongFileResponse.fromJson(Map<String, dynamic> json) {
    return SongFileResponse(
      id: json['id'] as int,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      fileType: json['fileType'] as String?,
      fileSize: json['fileSize'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SongUsageResponse {
  final int id;
  final int setlistId;
  final String setlistTitle;
  final String? usedKey;
  final DateTime usedAt;

  SongUsageResponse({
    required this.id,
    required this.setlistId,
    required this.setlistTitle,
    this.usedKey,
    required this.usedAt,
  });

  factory SongUsageResponse.fromJson(Map<String, dynamic> json) {
    return SongUsageResponse(
      id: json['id'] as int,
      setlistId: json['setlistId'] as int,
      setlistTitle: json['setlistTitle'] as String,
      usedKey: json['usedKey'] as String?,
      usedAt: DateTime.parse(json['usedAt'] as String),
    );
  }
}

class TagResponse {
  final String tag;
  final int count;

  TagResponse({required this.tag, required this.count});

  factory TagResponse.fromJson(Map<String, dynamic> json) {
    return TagResponse(
      tag: json['tag'] as String,
      count: json['count'] as int,
    );
  }
}

class SongCreateRequest {
  final String title;
  final String? artist;
  final String? originalKey;
  final int? bpm;
  final String? memo;
  final String? youtubeUrl;
  final String? musicUrl;
  final List<String>? tags;
  final List<SongSectionRequest>? sections;

  SongCreateRequest({
    required this.title,
    this.artist,
    this.originalKey,
    this.bpm,
    this.memo,
    this.youtubeUrl,
    this.musicUrl,
    this.tags,
    this.sections,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        if (artist != null) 'artist': artist,
        if (originalKey != null) 'originalKey': originalKey,
        if (bpm != null) 'bpm': bpm,
        if (memo != null) 'memo': memo,
        if (youtubeUrl != null) 'youtubeUrl': youtubeUrl,
        if (musicUrl != null) 'musicUrl': musicUrl,
        if (tags != null) 'tags': tags,
        if (sections != null)
          'sections': sections!.map((e) => e.toJson()).toList(),
      };
}

class SongUpdateRequest {
  final String? title;
  final String? artist;
  final String? originalKey;
  final int? bpm;
  final String? memo;
  final String? youtubeUrl;
  final String? musicUrl;
  final List<String>? tags;
  final List<SongSectionRequest>? sections;

  SongUpdateRequest({
    this.title,
    this.artist,
    this.originalKey,
    this.bpm,
    this.memo,
    this.youtubeUrl,
    this.musicUrl,
    this.tags,
    this.sections,
  });

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (artist != null) 'artist': artist,
        if (originalKey != null) 'originalKey': originalKey,
        if (bpm != null) 'bpm': bpm,
        if (memo != null) 'memo': memo,
        if (youtubeUrl != null) 'youtubeUrl': youtubeUrl,
        if (musicUrl != null) 'musicUrl': musicUrl,
        if (tags != null) 'tags': tags,
        if (sections != null)
          'sections': sections!.map((e) => e.toJson()).toList(),
      };
}
