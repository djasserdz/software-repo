class Warehouse {
  final int warehouseId;
  final int? managerId;
  final String name;
  final String location;
  final double xFloat;
  final double yFloat;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? distance;
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final double? totalCapacity;
  final double? availableCapacity;

  Warehouse({
    required this.warehouseId,
    this.managerId,
    required this.name,
    required this.location,
    required this.xFloat,
    required this.yFloat,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.distance,
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.totalCapacity,
    this.availableCapacity,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    // Helper function to safely convert to double
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Warehouse(
      warehouseId: _toInt(json['warehouse_id'] ?? json['warehouseId']),
      managerId: json['manager_id'] != null || json['managerId'] != null
          ? _toInt(json['manager_id'] ?? json['managerId'])
          : null,
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      xFloat: _toDouble(json['x_float'] ?? json['xFloat'] ?? 0.0),
      yFloat: _toDouble(json['y_float'] ?? json['yFloat'] ?? 0.0),
      status: json['status']?.toString() ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      distance: json['distance'] != null ? _toDouble(json['distance']) : null,
      street: json['street']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      zipCode: json['zip_code']?.toString() ?? json['zipCode']?.toString(),
      totalCapacity: json['total_capacity'] != null || json['totalCapacity'] != null
          ? _toDouble(json['total_capacity'] ?? json['totalCapacity'])
          : null,
      availableCapacity: json['available_capacity'] != null || json['availableCapacity'] != null
          ? _toDouble(json['available_capacity'] ?? json['availableCapacity'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouse_id': warehouseId,
      'manager_id': managerId,
      'name': name,
      'location': location,
      'x_float': xFloat,
      'y_float': yFloat,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'street': street,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'total_capacity': totalCapacity,
      'available_capacity': availableCapacity,
    };
  }
}

