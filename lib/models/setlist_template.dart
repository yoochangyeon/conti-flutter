class SetlistTemplateResponse {
  final int id;
  final String name;
  final String? description;
  final String? worshipType;
  final String? worshipTypeDisplayName;
  final int itemCount;
  final DateTime createdAt;
  final List<SetlistTemplateItemResponse> items;

  SetlistTemplateResponse({
    required this.id,
    required this.name,
    this.description,
    this.worshipType,
    this.worshipTypeDisplayName,
    required this.itemCount,
    required this.createdAt,
    required this.items,
  });

  factory SetlistTemplateResponse.fromJson(Map<String, dynamic> json) {
    return SetlistTemplateResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      worshipType: json['worshipType'] as String?,
      worshipTypeDisplayName: json['worshipTypeDisplayName'] as String?,
      itemCount: json['itemCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      items: (json['items'] as List?)
              ?.map((e) => SetlistTemplateItemResponse.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SetlistTemplateItemResponse {
  final int id;
  final String itemType;
  final String? itemTypeDisplayName;
  final int orderIndex;
  final int? songId;
  final String? title;
  final String? description;
  final int? durationMinutes;
  final String? color;
  final String? servicePhase;
  final String? servicePhaseDisplayName;

  SetlistTemplateItemResponse({
    required this.id,
    required this.itemType,
    this.itemTypeDisplayName,
    required this.orderIndex,
    this.songId,
    this.title,
    this.description,
    this.durationMinutes,
    this.color,
    this.servicePhase,
    this.servicePhaseDisplayName,
  });

  factory SetlistTemplateItemResponse.fromJson(Map<String, dynamic> json) {
    return SetlistTemplateItemResponse(
      id: json['id'] as int,
      itemType: json['itemType'] as String,
      itemTypeDisplayName: json['itemTypeDisplayName'] as String?,
      orderIndex: json['orderIndex'] as int,
      songId: json['songId'] as int?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      color: json['color'] as String?,
      servicePhase: json['servicePhase'] as String?,
      servicePhaseDisplayName: json['servicePhaseDisplayName'] as String?,
    );
  }
}
