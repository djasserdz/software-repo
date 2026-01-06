import 'api_service.dart';
import '../models/delivery.dart';

class DeliveryService {
  final ApiService apiService;

  DeliveryService(this.apiService);

  /// Get all deliveries
  /// - Admin: sees all deliveries
  /// - WarehouseAdmin: sees only deliveries from their warehouse
  /// - Farmer: sees only their own deliveries
  Future<List<Delivery>> getAllDeliveries({
    int? warehouseId,
    int? appointmentId,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      
      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId;
      if (appointmentId != null) queryParams['appointment_id'] = appointmentId;
      if (status != null) queryParams['status'] = status;

      final response = await apiService.get(
        '/delivery',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((d) => Delivery.fromJson(d as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch deliveries');
    } catch (e) {
      rethrow;
    }
  }

  /// Get deliveries for current farmer
  Future<List<Delivery>> getMyDeliveries({String? status}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (status != null) queryParams['status'] = status;

      final response = await apiService.get(
        '/delivery/my-deliveries',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> deliveries = data['deliveries'] ?? [];
        return deliveries.map((d) => Delivery.fromJson(d as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch my deliveries');
    } catch (e) {
      rethrow;
    }
  }

  /// Get deliveries for a specific warehouse (warehouse admin only)
  Future<List<Delivery>> getWarehouseDeliveries({
    required int warehouseId,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (status != null) queryParams['status'] = status;

      final response = await apiService.get(
        '/delivery/warehouse/$warehouseId',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> deliveries = data['deliveries'] ?? [];
        return deliveries.map((d) => Delivery.fromJson(d as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch warehouse deliveries');
    } catch (e) {
      rethrow;
    }
  }

  /// Get delivery by ID
  /// - WarehouseAdmin can only see deliveries from their warehouse
  /// - Farmer can only see their own deliveries
  Future<Delivery> getDeliveryById(int deliveryId) async {
    try {
      final response = await apiService.get('/delivery/$deliveryId');
      
      if (response.statusCode == 200) {
        return Delivery.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to fetch delivery');
    } catch (e) {
      rethrow;
    }
  }

  /// Create new delivery (warehouse admin only)
  /// - Must have access to the appointment's warehouse
  Future<Delivery> createDelivery({
    required int appointmentId,
    required int actualDeliveredQuantity,
    String? deliveryNotes,
  }) async {
    try {
      final response = await apiService.post(
        '/delivery',
        data: {
          'appointmentId': appointmentId,
          'actualDeliveredQuantity': actualDeliveredQuantity,
          if (deliveryNotes != null) 'deliveryNotes': deliveryNotes,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Delivery.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to create delivery');
    } catch (e) {
      rethrow;
    }
  }

  /// Update delivery status (warehouse admin only)
  /// - Must have access to the delivery's warehouse
  Future<Delivery> updateDeliveryStatus({
    required int deliveryId,
    required String status,
    String? notes,
  }) async {
    try {
      final response = await apiService.put(
        '/delivery/$deliveryId/status',
        data: {
          'status': status,
          if (notes != null) 'notes': notes,
        },
      );
      
      if (response.statusCode == 200) {
        return Delivery.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to update delivery status');
    } catch (e) {
      rethrow;
    }
  }

  /// Complete delivery (warehouse admin only)
  /// - Must have access to the delivery's warehouse
  Future<Delivery> completeDelivery(int deliveryId) async {
    try {
      final response = await apiService.put(
        '/delivery/$deliveryId/complete',
      );
      
      if (response.statusCode == 200) {
        return Delivery.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to complete delivery');
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel delivery (warehouse admin only)
  /// - Must have access to the delivery's warehouse
  /// - Cancellation may have restrictions based on delivery status
  Future<void> cancelDelivery(int deliveryId) async {
    try {
      final response = await apiService.put(
        '/delivery/$deliveryId/cancel',
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to cancel delivery');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get delivery history (farmer only)
  Future<List<Delivery>> getDeliveryHistory() async {
    try {
      final response = await apiService.get('/delivery/history');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> deliveries = data['deliveries'] ?? [];
        return deliveries.map((d) => Delivery.fromJson(d as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch delivery history');
    } catch (e) {
      rethrow;
    }
  }

  /// Get delivery statistics for warehouse (warehouse admin only)
  Future<Map<String, dynamic>> getWarehouseDeliveryStats(int warehouseId) async {
    try {
      final response = await apiService.get(
        '/delivery/warehouse/$warehouseId/stats',
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch delivery statistics');
    } catch (e) {
      rethrow;
    }
  }

  /// Get delivery statistics for farmer (farmer only)
  Future<Map<String, dynamic>> getDeliveryStats() async {
    try {
      final response = await apiService.get('/delivery/stats');
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch delivery statistics');
    } catch (e) {
      rethrow;
    }
  }
}
