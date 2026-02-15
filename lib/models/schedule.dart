export 'schedule_matrix.dart';

enum WorshipType {
  sunday1st('주일 1부 예배', 'SUNDAY_1ST'),
  sunday2nd('주일 2부 예배', 'SUNDAY_2ND'),
  sunday3rd('주일 3부 예배', 'SUNDAY_3RD'),
  wednesday('수요 예배', 'WEDNESDAY'),
  friday('금요 예배', 'FRIDAY'),
  dawn('새벽 예배', 'DAWN'),
  youth('청년 예배', 'YOUTH'),
  retreat('수련회', 'RETREAT'),
  special('특별 예배', 'SPECIAL'),
  other('기타', 'OTHER');

  final String displayName;
  final String jsonValue;
  const WorshipType(this.displayName, this.jsonValue);

  static WorshipType? fromName(String? name) {
    if (name == null) return null;
    try {
      return WorshipType.values.firstWhere((e) => e.jsonValue == name);
    } catch (_) {
      return null;
    }
  }
}

enum MemberPosition {
  worshipLeader('인도자', 'WORSHIP_LEADER'),
  vocal('보컬', 'VOCAL'),
  acousticGuitar('어쿠스틱 기타', 'ACOUSTIC_GUITAR'),
  electricGuitar('일렉 기타', 'ELECTRIC_GUITAR'),
  bass('베이스', 'BASS'),
  drum('드럼', 'DRUM'),
  keyboard('키보드', 'KEYBOARD'),
  piano('피아노', 'PIANO'),
  synth('신디사이저', 'SYNTH'),
  pad('패드', 'PAD'),
  violin('바이올린', 'VIOLIN'),
  cello('첼로', 'CELLO'),
  flute('플룻', 'FLUTE'),
  sound('음향', 'SOUND'),
  visual('영상', 'VISUAL'),
  other('기타', 'OTHER');

  final String displayName;
  final String jsonValue;
  const MemberPosition(this.displayName, this.jsonValue);

  static MemberPosition? fromName(String? name) {
    if (name == null) return null;
    try {
      return MemberPosition.values.firstWhere((e) => e.jsonValue == name);
    } catch (_) {
      return null;
    }
  }
}

enum ScheduleStatus {
  pending('대기', 'PENDING'),
  accepted('수락', 'ACCEPTED'),
  declined('거절', 'DECLINED');

  final String displayName;
  final String jsonValue;
  const ScheduleStatus(this.displayName, this.jsonValue);

  static ScheduleStatus? fromName(String? name) {
    if (name == null) return null;
    try {
      return ScheduleStatus.values.firstWhere((e) => e.jsonValue == name);
    } catch (_) {
      return null;
    }
  }
}

enum SetlistItemType {
  song('찬양', 'SONG'),
  prayer('기도', 'PRAYER'),
  sermon('설교', 'SERMON'),
  offering('헌금', 'OFFERING'),
  announcement('광고', 'ANNOUNCEMENT'),
  scripture('성경 봉독', 'SCRIPTURE'),
  creed('사도신경', 'CREED'),
  benediction('축도', 'BENEDICTION'),
  prelude('전주', 'PRELUDE'),
  postlude('후주', 'POSTLUDE'),
  transition('전환', 'TRANSITION'),
  custom('기타', 'CUSTOM');

  final String displayName;
  final String jsonValue;
  const SetlistItemType(this.displayName, this.jsonValue);

  static SetlistItemType? fromName(String? name) {
    if (name == null) return null;
    try {
      return SetlistItemType.values.firstWhere((e) => e.jsonValue == name);
    } catch (_) {
      return null;
    }
  }
}

class ServiceScheduleResponse {
  final int id;
  final int setlistId;
  final int teamMemberId;
  final String memberName;
  final String? profileImage;
  final String position;
  final String positionDisplayName;
  final String status;
  final String statusDisplayName;
  final String? declinedReason;
  final DateTime? notifiedAt;
  final DateTime? respondedAt;

  ServiceScheduleResponse({
    required this.id,
    required this.setlistId,
    required this.teamMemberId,
    required this.memberName,
    this.profileImage,
    required this.position,
    required this.positionDisplayName,
    required this.status,
    required this.statusDisplayName,
    this.declinedReason,
    this.notifiedAt,
    this.respondedAt,
  });

  factory ServiceScheduleResponse.fromJson(Map<String, dynamic> json) {
    return ServiceScheduleResponse(
      id: json['id'] as int,
      setlistId: json['setlistId'] as int,
      teamMemberId: json['teamMemberId'] as int,
      memberName: json['memberName'] as String,
      profileImage: json['profileImage'] as String?,
      position: json['position'] as String,
      positionDisplayName: json['positionDisplayName'] as String,
      status: json['status'] as String,
      statusDisplayName: json['statusDisplayName'] as String,
      declinedReason: json['declinedReason'] as String?,
      notifiedAt: json['notifiedAt'] != null
          ? DateTime.parse(json['notifiedAt'] as String)
          : null,
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
    );
  }

  ScheduleStatus? get statusEnum => ScheduleStatus.fromName(status);
  MemberPosition? get positionEnum => MemberPosition.fromName(position);
}

class BlockoutDateResponse {
  final int id;
  final int teamMemberId;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;

  BlockoutDateResponse({
    required this.id,
    required this.teamMemberId,
    required this.startDate,
    required this.endDate,
    this.reason,
  });

  factory BlockoutDateResponse.fromJson(Map<String, dynamic> json) {
    return BlockoutDateResponse(
      id: json['id'] as int,
      teamMemberId: json['teamMemberId'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      reason: json['reason'] as String?,
    );
  }
}

class ScheduleConflictResponse {
  final int teamMemberId;
  final String memberName;
  final String position;
  final String conflictType;
  final String conflictDetail;

  ScheduleConflictResponse({
    required this.teamMemberId,
    required this.memberName,
    required this.position,
    required this.conflictType,
    required this.conflictDetail,
  });

  factory ScheduleConflictResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleConflictResponse(
      teamMemberId: json['teamMemberId'] as int,
      memberName: json['memberName'] as String,
      position: json['position'] as String,
      conflictType: json['conflictType'] as String,
      conflictDetail: json['conflictDetail'] as String,
    );
  }
}
