class StorageZone {
  final int zoneId;
  final int warehouseId;
  final int grainTypeId;
  final String name;
  final int totalCapacity;
  final int availableCapacity;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StorageZone({
    required this.zoneId,
    required this.warehouseId,
    required this.grainTypeId,
    required this.name,
    required this.totalCapacity,
    required this.availableCapacity,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory StorageZone.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    return StorageZone(
      zoneId: _toInt(json['zone_id'] ?? json['zoneId']),
      warehouseId: _toInt(json['warehouse_id'] ?? json['warehouseId']),
      grainTypeId: _toInt(json['grain_type_id'] ?? json['grainTypeId']),
      name: json['name']?.toString() ?? '',
      totalCapacity: _toInt(json['total_capacity'] ?? json['totalCapacity'] ?? 0),
      availableCapacity: _toInt(json['available_capacity'] ?? json['availableCapacity'] ?? 0),
      status: json['status']?.toString() ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zone_id': zoneId,
      'warehouse_id': warehouseId,
      'grain_type_id': grainTypeId,
      'name': name,
      'total_capacity': totalCapacity,
      'available_capacity': availableCapacity,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  double get capacityPercentage => totalCapacity > 0 
      ? (availableCapacity / totalCapacity) * 100 
      : 0.0;
}

