class AppConstants {
  AppConstants._();

  static const String appName = 'Conti';
  static const String baseUrl = 'http://localhost:8080';
  static const String apiPrefix = '/api/v1';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  // Pagination
  static const int defaultPageSize = 20;

  // Music keys
  static const List<String> musicKeys = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
    'Cm', 'C#m', 'Dm', 'D#m', 'Em', 'Fm', 'F#m', 'Gm', 'G#m', 'Am', 'A#m', 'Bm',
  ];

  // Worship types — use WorshipType enum from models/schedule.dart as source of truth
  // Kept for backward compatibility; prefer WorshipType.values in new code.
  static List<String> get worshipTypes =>
      _worshipTypeCache;
  static final List<String> _worshipTypeCache = [
    'SUNDAY_1ST', 'SUNDAY_2ND', 'SUNDAY_3RD', 'WEDNESDAY',
    'FRIDAY', 'DAWN', 'YOUTH', 'RETREAT', 'SPECIAL', 'OTHER',
  ];

  // Team roles
  static const String roleAdmin = 'ADMIN';
  static const String roleViewer = 'VIEWER';

  // Section types
  static const List<String> sectionTypes = [
    'INTRO', 'VERSE', 'PRE_CHORUS', 'CHORUS', 'BRIDGE',
    'INTERLUDE', 'OUTRO', 'TAG', 'ENDING', 'CUSTOM',
  ];

  static const Map<String, String> sectionTypeNames = {
    'INTRO': '인트로',
    'VERSE': '벌스',
    'PRE_CHORUS': '프리코러스',
    'CHORUS': '코러스',
    'BRIDGE': '브릿지',
    'INTERLUDE': '인터루드',
    'OUTRO': '아웃트로',
    'TAG': '태그',
    'ENDING': '엔딩',
    'CUSTOM': '커스텀',
  };
}
