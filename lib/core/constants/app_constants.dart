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

  // Worship types
  static const List<String> worshipTypes = [
    '주일 1부 예배',
    '주일 2부 예배',
    '주일 3부 예배',
    '수요 예배',
    '금요 기도회',
    '새벽 예배',
    '청년 예배',
    '기타',
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
