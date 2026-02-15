class ScheduleMatrixResponse {
  final List<String> positions;
  final List<String> positionDisplayNames;
  final List<DateTime> dates;
  final List<DateSetlistInfo> dateSetlists;
  final List<MatrixCell> cells;

  ScheduleMatrixResponse({
    required this.positions,
    required this.positionDisplayNames,
    required this.dates,
    required this.dateSetlists,
    required this.cells,
  });

  factory ScheduleMatrixResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleMatrixResponse(
      positions: (json['positions'] as List).cast<String>(),
      positionDisplayNames: (json['positionDisplayNames'] as List).cast<String>(),
      dates: (json['dates'] as List)
          .map((e) => DateTime.parse(e as String))
          .toList(),
      dateSetlists: (json['dateSetlists'] as List)
          .map((e) => DateSetlistInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      cells: (json['cells'] as List)
          .map((e) => MatrixCell.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DateSetlistInfo {
  final DateTime date;
  final int setlistId;
  final String? worshipType;
  final String? worshipTypeDisplayName;
  final String? title;

  DateSetlistInfo({
    required this.date,
    required this.setlistId,
    this.worshipType,
    this.worshipTypeDisplayName,
    this.title,
  });

  factory DateSetlistInfo.fromJson(Map<String, dynamic> json) {
    return DateSetlistInfo(
      date: DateTime.parse(json['date'] as String),
      setlistId: json['setlistId'] as int,
      worshipType: json['worshipType'] as String?,
      worshipTypeDisplayName: json['worshipTypeDisplayName'] as String?,
      title: json['title'] as String?,
    );
  }
}

class MatrixCell {
  final DateTime date;
  final String position;
  final List<CellMember> members;

  MatrixCell({
    required this.date,
    required this.position,
    required this.members,
  });

  factory MatrixCell.fromJson(Map<String, dynamic> json) {
    return MatrixCell(
      date: DateTime.parse(json['date'] as String),
      position: json['position'] as String,
      members: (json['members'] as List)
          .map((e) => CellMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CellMember {
  final int scheduleId;
  final int teamMemberId;
  final String memberName;
  final String? profileImage;
  final String status;
  final String statusDisplayName;

  CellMember({
    required this.scheduleId,
    required this.teamMemberId,
    required this.memberName,
    this.profileImage,
    required this.status,
    required this.statusDisplayName,
  });

  factory CellMember.fromJson(Map<String, dynamic> json) {
    return CellMember(
      scheduleId: json['scheduleId'] as int,
      teamMemberId: json['teamMemberId'] as int,
      memberName: json['memberName'] as String,
      profileImage: json['profileImage'] as String?,
      status: json['status'] as String,
      statusDisplayName: json['statusDisplayName'] as String,
    );
  }
}
