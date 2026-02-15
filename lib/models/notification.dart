enum NotificationType {
  scheduleAssigned('봉사 배정', 'SCHEDULE_ASSIGNED'),
  scheduleResponse('배정 응답', 'SCHEDULE_RESPONSE'),
  scheduleReminder('봉사 리마인더', 'SCHEDULE_REMINDER'),
  setlistUpdated('콘티 수정', 'SETLIST_UPDATED');

  final String displayName;
  final String jsonValue;
  const NotificationType(this.displayName, this.jsonValue);

  static NotificationType? fromName(String? name) {
    if (name == null) return null;
    try {
      return NotificationType.values.firstWhere((e) => e.jsonValue == name);
    } catch (_) {
      return null;
    }
  }
}

class NotificationResponse {
  final int id;
  final String type;
  final String typeDisplayName;
  final String title;
  final String message;
  final String? referenceType;
  final int? referenceId;
  final bool isRead;
  final DateTime createdAt;

  NotificationResponse({
    required this.id,
    required this.type,
    required this.typeDisplayName,
    required this.title,
    required this.message,
    this.referenceType,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      id: json['id'] as int,
      type: json['type'] as String,
      typeDisplayName: json['typeDisplayName'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as int?,
      isRead: json['isRead'] as bool? ?? json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  NotificationType? get typeEnum => NotificationType.fromName(type);
}

class UnreadCountResponse {
  final int count;

  UnreadCountResponse({required this.count});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      count: json['count'] as int,
    );
  }
}
