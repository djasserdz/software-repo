import 'package:flutter/foundation.dart';
import '../models/delivery.dart';
import '../services/api_service.dart';

class DeliveryProvider with ChangeNotifier {
  final ApiService apiService;
  
  List<Delivery> _deliveries = [];
  List<Delivery> _filteredDeliveries = [];
  Delivery? _selectedDelivery;
  bool _isLoading = false;
  String? _error;
  String _statusFilter = '';

  DeliveryProvider(this.apiService);

  // Getters
  List<Delivery> get deliveries => _deliveries;
  List<Delivery> get filteredDeliveries => _filteredDeliveries;
  Delivery? get selectedDelivery => _selectedDelivery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all deliveries for current user
  Future<void> fetchDeliveries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/deliveries');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        _deliveries = data.map((d) => Delivery.fromJson(d)).toList();
        _filteredDeliveries = _deliveries;
        _error = null;
      } else {
        _error = 'Failed to fetch deliveries';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch single delivery
  Future<void> fetchDeliveryById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/deliveries/$id');
      if (response.statusCode == 200) {
        _selectedDelivery = Delivery.fromJson(response.data['data']);
        _error = null;
      } else {
        _error = 'Failed to fetch delivery';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new delivery
  Future<bool> createDelivery({
    required int warehouseId,
    int? appointmentId,
    int? grainId,
    required int quantityBags,
    required String deliveryDate,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.post(
        '/deliveries',
        data: {
          'warehouse_id': warehouseId,
          'appointment_id': appointmentId,
          'grain_id': grainId,
          'quantity_bags': quantityBags,
          'delivery_date': deliveryDate,
          'notes': notes,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchDeliveries();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to create delivery';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update delivery status
  Future<bool> updateDeliveryStatus({
    required int deliveryId,
    required String status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.put(
        '/deliveries/$deliveryId',
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        await fetchDeliveries();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to update delivery';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter by status
  void filterByStatus(String status) {
    _statusFilter = status.toLowerCase();
    if (_statusFilter.isEmpty) {
      _filteredDeliveries = _deliveries;
    } else {
      _filteredDeliveries = _deliveries
          .where((d) => d.status.toLowerCase() == _statusFilter)
          .toList();
    }
    notifyListeners();
  }

  // Get recent deliveries
  List<Delivery> getRecentDeliveries({int limit = 5}) {
    final recent = List<Delivery>.from(_deliveries);
    recent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return recent.take(limit).toList();
  }

  // Get delivery statistics
  Map<String, int> getDeliveryStats() {
    return {
      'total': _deliveries.length,
      'pending': _deliveries.where((d) => d.status.toLowerCase() == 'pending').length,
      'in_transit': _deliveries.where((d) => d.status.toLowerCase() == 'in_transit').length,
      'delivered': _deliveries.where((d) => d.status.toLowerCase() == 'delivered').length,
      'failed': _deliveries.where((d) => d.status.toLowerCase() == 'failed').length,
    };
  }

  // Calculate total quantity delivered
  int getTotalQuantityDelivered() {
    return _deliveries
        .where((d) => d.status.toLowerCase() == 'delivered')
        .fold(0, (sum, d) => sum + d.actualDeliveredQuantity);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
