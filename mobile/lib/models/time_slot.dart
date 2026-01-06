class TimeSlot {
  final int timeId;
  final int zoneId;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TimeSlot({
    required this.timeId,
    required this.zoneId,
    required this.startAt,
    required this.endAt,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      timeId: json['time_id'] ?? json['timeId'],
      zoneId: json['zone_id'] ?? json['zoneId'],
      startAt: DateTime.parse(json['start_at'] ?? json['startAt']),
      endAt: DateTime.parse(json['end_at'] ?? json['endAt']),
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time_id': timeId,
      'zone_id': zoneId,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

