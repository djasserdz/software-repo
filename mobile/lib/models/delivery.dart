class Delivery {
  final int id;
  final int appointmentId;
  final int warehouseZoneId;
  final int grainTypeId;
  final int farmerId;
  final int actualDeliveredQuantity;
  final String status;
  final String? deliveryNotes;
  final DateTime createdAt;
  final DateTime? completedAt;

  Delivery({
    required this.id,
    required this.appointmentId,
    required this.warehouseZoneId,
    required this.grainTypeId,
    required this.farmerId,
    required this.actualDeliveredQuantity,
    required this.status,
    this.deliveryNotes,
    required this.createdAt,
    this.completedAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] as int,
      appointmentId: json['appointmentId'] as int,
      warehouseZoneId: json['warehouseZoneId'] as int,
      grainTypeId: json['grainTypeId'] as int,
      farmerId: json['farmerId'] as int,
      actualDeliveredQuantity: json['actualDeliveredQuantity'] as int,
      status: json['status'] as String,
      deliveryNotes: json['deliveryNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null 
        ? DateTime.parse(json['completedAt'] as String)
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'warehouseZoneId': warehouseZoneId,
      'grainTypeId': grainTypeId,
      'farmerId': farmerId,
      'actualDeliveredQuantity': actualDeliveredQuantity,
      'status': status,
      'deliveryNotes': deliveryNotes,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // Delivery status constants
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String failed = 'failed';

  bool get isPending => status == pending;
  bool get isInProgress => status == inProgress;
  bool get isCompleted => status == completed;
  bool get isCancelled => status == cancelled;
  bool get isFailed => status == failed;

  String get statusDisplay {
    switch (status) {
      case pending:
        return 'Pending';
      case inProgress:
        return 'In Progress';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      case failed:
        return 'Failed';
      default:
        return status;
    }
  }
}
