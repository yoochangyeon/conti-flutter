class TopSongResponse {
  final int songId;
  final String title;
  final String? artist;
  final String? originalKey;
  final int usageCount;
  final String? lastUsedAt;

  TopSongResponse({
    required this.songId,
    required this.title,
    this.artist,
    this.originalKey,
    required this.usageCount,
    this.lastUsedAt,
  });

  factory TopSongResponse.fromJson(Map<String, dynamic> json) {
    return TopSongResponse(
      songId: json['songId'] as int,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      originalKey: json['originalKey'] as String?,
      usageCount: (json['usageCount'] as num).toInt(),
      lastUsedAt: json['lastUsedAt'] as String?,
    );
  }
}

class SongStatsResponse {
  final int songId;
  final String title;
  final String? artist;
  final int totalUsageCount;
  final String? lastUsedAt;
  final List<MonthlyUsage> monthlyUsages;
  final List<KeyUsage> keyDistribution;
  final List<LeaderUsage> leaderBreakdown;

  SongStatsResponse({
    required this.songId,
    required this.title,
    this.artist,
    required this.totalUsageCount,
    this.lastUsedAt,
    required this.monthlyUsages,
    required this.keyDistribution,
    required this.leaderBreakdown,
  });

  factory SongStatsResponse.fromJson(Map<String, dynamic> json) {
    return SongStatsResponse(
      songId: json['songId'] as int,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      totalUsageCount: (json['totalUsageCount'] as num).toInt(),
      lastUsedAt: json['lastUsedAt'] as String?,
      monthlyUsages: (json['monthlyUsages'] as List?)
              ?.map(
                  (e) => MonthlyUsage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      keyDistribution: (json['keyDistribution'] as List?)
              ?.map((e) => KeyUsage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      leaderBreakdown: (json['leaderBreakdown'] as List?)
              ?.map(
                  (e) => LeaderUsage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MonthlyUsage {
  final int year;
  final int month;
  final int count;

  MonthlyUsage({required this.year, required this.month, required this.count});

  factory MonthlyUsage.fromJson(Map<String, dynamic> json) {
    return MonthlyUsage(
      year: json['year'] as int,
      month: json['month'] as int,
      count: (json['count'] as num).toInt(),
    );
  }
}

class KeyUsage {
  final String key;
  final int count;

  KeyUsage({required this.key, required this.count});

  factory KeyUsage.fromJson(Map<String, dynamic> json) {
    return KeyUsage(
      key: json['key'] as String,
      count: (json['count'] as num).toInt(),
    );
  }
}

class LeaderUsage {
  final int leaderId;
  final String leaderName;
  final int count;

  LeaderUsage({
    required this.leaderId,
    required this.leaderName,
    required this.count,
  });

  factory LeaderUsage.fromJson(Map<String, dynamic> json) {
    return LeaderUsage(
      leaderId: json['leaderId'] as int,
      leaderName: json['leaderName'] as String,
      count: (json['count'] as num).toInt(),
    );
  }
}
