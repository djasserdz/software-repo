class Grain {
  final int grainId;
  final String name;
  final double price;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Grain({
    required this.grainId,
    required this.name,
    required this.price,
    this.createdAt,
    this.updatedAt,
  });

  factory Grain.fromJson(Map<String, dynamic> json) {
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

    return Grain(
      grainId: _toInt(json['grain_id'] ?? json['grainId']),
      name: json['name']?.toString() ?? '',
      price: _toDouble(json['price'] ?? 0.0),
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
      'grain_id': grainId,
      'name': name,
      'price': price,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

