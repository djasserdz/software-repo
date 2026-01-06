class TimeSlotTemplate {
  final int templateId;
  final int zoneId;
  final int dayOfWeek; // 0=Monday, 6=Sunday
  final String startTime; // HH:MM:SS
  final String endTime; // HH:MM:SS
  final int maxAppointments;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimeSlotTemplate({
    required this.templateId,
    required this.zoneId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.maxAppointments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TimeSlotTemplate.fromJson(Map<String, dynamic> json) {
    return TimeSlotTemplate(
      templateId: json['template_id'] ?? 0,
      zoneId: json['zone_id'] ?? 0,
      dayOfWeek: json['day_of_week'] ?? 0,
      startTime: json['start_time'] ?? '09:00:00',
      endTime: json['end_time'] ?? '17:00:00',
      maxAppointments: json['max_appointments'] ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'template_id': templateId,
      'zone_id': zoneId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'max_appointments': maxAppointments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String getDayName() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek];
  }
}
