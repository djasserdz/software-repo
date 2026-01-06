import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/storage_zone.dart';

class ZoneProvider extends ChangeNotifier {
  final ApiService _apiService;

  ZoneProvider(this._apiService);

  List<StorageZone> _zones = [];
  List<StorageZone> _filteredZones = [];
  StorageZone? _selectedZone;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<StorageZone> get zones => _filteredZones;
  StorageZone? get selectedZone => _selectedZone;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all zones
  Future<void> fetchZones({
    int? warehouseId,
    int? grainTypeId,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId;
      if (grainTypeId != null) queryParams['grain_type_id'] = grainTypeId;
      if (status != null) queryParams['status'] = status;

      final response = await _apiService.get('/zone/', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);
        _zones = data.map((z) => StorageZone.fromJson(z as Map<String, dynamic>)).toList();
        _filteredZones = _zones;
        _error = null;
      } else {
        _error = 'Failed to fetch zones: ${response.statusCode}';
      }
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create zone
  Future<bool> createZone({
    required int warehouseId,
    required String name,
    required int grainTypeId,
    required int totalCapacity,
    required String status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/zone/',
        data: {
          'name': name,
          'grain_type_id': grainTypeId,
          'total_capacity': totalCapacity,
          'available_capacity': totalCapacity, // Set to total for new zones
          'status': status,
        },
        queryParameters: {'warehouse_id': warehouseId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchZones();
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to create zone';
        return false;
      }
    } catch (e) {
      _error = _formatError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update zone
  Future<bool> updateZone({
    required int zoneId,
    String? name,
    int? grainTypeId,
    int? totalCapacity,
    int? availableCapacity,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (grainTypeId != null) data['grain_type_id'] = grainTypeId;
      if (totalCapacity != null) data['total_capacity'] = totalCapacity;
      if (availableCapacity != null) data['available_capacity'] = availableCapacity;
      if (status != null) data['status'] = status;

      final response = await _apiService.patch('/zone/$zoneId', data: data);

      if (response.statusCode == 200) {
        await fetchZones();
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to update zone';
        return false;
      }
    } catch (e) {
      _error = _formatError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter zones
  void filterZones({
    int? warehouseId,
    int? grainTypeId,
    String? status,
  }) {
    _filteredZones = _zones.where((zone) {
      if (warehouseId != null && zone.warehouseId != warehouseId) return false;
      if (grainTypeId != null && zone.grainTypeId != grainTypeId) return false;
      if (status != null && zone.status != status) return false;
      return true;
    }).toList();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _formatError(dynamic error) {
    if (error.toString().contains('DioException')) {
      if (error.toString().contains('SocketException') || 
          error.toString().contains('Failed host lookup')) {
        return 'Network error: Please check your internet connection';
      } else if (error.toString().contains('404')) {
        return 'Resource not found';
      } else if (error.toString().contains('401')) {
        return 'Unauthorized: Please login again';
      } else if (error.toString().contains('500')) {
        return 'Server error: Please try again later';
      } else if (error.toString().contains('timeout')) {
        return 'Request timeout: Please try again';
      }
      return 'Network error: ${error.toString()}';
    }
    return error.toString();
  }
}

