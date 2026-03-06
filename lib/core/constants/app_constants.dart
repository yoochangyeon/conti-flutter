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

  // Worship types — prefer WorshipType enum from models/schedule.dart
  static List<String> get worshipTypes => _worshipTypeCache;
  static final List<String> _worshipTypeCache = [
    'SUNDAY_1ST', 'SUNDAY_2ND', 'SUNDAY_3RD', 'WEDNESDAY',
    'FRIDAY', 'DAWN', 'YOUTH', 'RETREAT', 'SPECIAL', 'OTHER',
  ];

  /// 예배 타입 한국어 표시명
  static const Map<String, String> worshipTypeNames = {
    'SUNDAY_1ST': '주일 1부 예배',
    'SUNDAY_2ND': '주일 2부 예배',
    'SUNDAY_3RD': '주일 3부 예배',
    'WEDNESDAY': '수요 예배',
    'FRIDAY': '금요 예배',
    'DAWN': '새벽 예배',
    'YOUTH': '청년 예배',
    'RETREAT': '수련회',
    'SPECIAL': '특별 예배',
    'OTHER': '기타',
  };

  // Team roles
  static const String roleAdmin = 'ADMIN';
  static const String roleViewer = 'VIEWER';

  /// 팀 역할 한국어 표시명
  static const Map<String, String> roleNames = {
    'ADMIN': '관리자',
    'VIEWER': '멤버',
    'GUEST': '게스트',
  };

  // Section types
  static const List<String> sectionTypes = [
    'INTRO', 'VERSE', 'PRE_CHORUS', 'CHORUS', 'BRIDGE',
    'INTERLUDE', 'OUTRO', 'TAG', 'ENDING', 'CUSTOM',
  ];

  static const Map<String, String> sectionTypeNames = {
    'INTRO': '인트로',
    'VERSE': '절',
    'PRE_CHORUS': '프리코러스',
    'CHORUS': '후렴',
    'BRIDGE': '브릿지',
    'INTERLUDE': '간주',
    'OUTRO': '아웃트로',
    'TAG': '태그',
    'ENDING': '엔딩',
    'CUSTOM': '직접 입력',
  };

  /// 포지션 한국어 표시명
  static const Map<String, String> positionNames = {
    'WORSHIP_LEADER': '인도자',
    'VOCAL': '보컬',
    'ACOUSTIC_GUITAR': '어쿠스틱 기타',
    'ELECTRIC_GUITAR': '일렉 기타',
    'BASS': '베이스',
    'DRUM': '드럼',
    'KEYBOARD': '키보드',
    'PIANO': '피아노',
    'SYNTH': '신디사이저',
    'PAD': '패드',
    'VIOLIN': '바이올린',
    'CELLO': '첼로',
    'FLUTE': '플룻',
    'SOUND': '음향',
    'VISUAL': '영상',
    'OTHER': '기타',
  };

  /// 스케줄 상태 한국어 표시명
  static const Map<String, String> scheduleStatusNames = {
    'PENDING': '대기 중',
    'ACCEPTED': '수락됨',
    'DECLINED': '거절됨',
  };

  /// 세트리스트 아이템 타입 한국어 표시명
  static const Map<String, String> itemTypeNames = {
    'SONG': '찬양',
    'SERMON': '설교',
    'PRAYER': '기도',
    'READING': '성경 봉독',
    'ANNOUNCEMENT': '광고',
    'OFFERING': '헌금',
    'OTHER': '기타',
  };
}
