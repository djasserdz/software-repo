class Appointment {
  final int appointmentId;
  final int farmerId;
  final int zoneId;
  final int grainTypeId;
  final int requestedQuantity;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? warehouseName;
  final String? zoneName;
  final String? grainTypeName;
  final String? warehouseLocation;

  Appointment({
    required this.appointmentId,
    required this.farmerId,
    required this.zoneId,
    required this.grainTypeId,
    required this.requestedQuantity,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.warehouseName,
    this.zoneName,
    this.grainTypeName,
    this.warehouseLocation,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    // Extract warehouse name from nested structure
    String? warehouseName;
    String? warehouseLocation;
    if (json['warehouseZone'] != null && json['warehouseZone']['warehouse'] != null) {
      warehouseName = json['warehouseZone']['warehouse']['name'];
      warehouseLocation = json['warehouseZone']['warehouse']['location'];
    }

    // Extract zone name
    String? zoneName;
    if (json['warehouseZone'] != null) {
      zoneName = json['warehouseZone']['name'];
    }

    // Extract grain type name from nested grain_type
    String? grainTypeName;
    if (json['grain_type'] != null && json['grain_type'] is Map) {
      grainTypeName = json['grain_type']['name'];
    }

    return Appointment(
      appointmentId: _toInt(json['appointment_id'] ?? json['appointmentId']),
      farmerId: _toInt(json['farmer_id'] ?? json['farmerId']),
      zoneId: _toInt(json['zone_id'] ?? json['zoneId']),
      grainTypeId: _toInt(json['grain_type_id'] ?? json['grainTypeId']),
      requestedQuantity: _toInt(json['requested_quantity'] ?? json['requestedQuantity']),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      warehouseName: warehouseName,
      zoneName: zoneName,
      grainTypeName: grainTypeName,
      warehouseLocation: warehouseLocation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointment_id': appointmentId,
      'farmer_id': farmerId,
      'zone_id': zoneId,
      'grain_type_id': grainTypeId,
      'requested_quantity': requestedQuantity,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

