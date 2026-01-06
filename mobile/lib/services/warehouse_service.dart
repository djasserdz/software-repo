import 'api_service.dart';
import '../models/warehouse.dart';
import '../models/storage_zone.dart';
import '../models/grain.dart';

class WarehouseService {
  final ApiService apiService;

  WarehouseService(this.apiService);

  /// Get all warehouses (with access control)
  /// - Admin: sees all warehouses
  /// - WarehouseAdmin: sees only their assigned warehouse
  /// - Farmer: sees all warehouses (read-only)
  Future<List<Warehouse>> getAllWarehouses() async {
    try {
      final response = await apiService.get('/warehouse');
      
      if (response.statusCode == 200) {
        // Backend returns list directly
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);
        return data.map((w) => Warehouse.fromJson(w as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch warehouses: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading warehouses: ${_formatError(e)}');
    }
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
    }
    return error.toString();
  }

  /// Get a specific warehouse by ID
  /// - WarehouseAdmin can only access their own warehouse
  Future<Warehouse> getWarehouseById(int warehouseId) async {
    try {
      final response = await apiService.get('/warehouse/$warehouseId');
      
      if (response.statusCode == 200) {
        // Backend returns object directly
        final data = response.data is Map 
            ? response.data 
            : (response.data['data'] ?? {});
        return Warehouse.fromJson(data as Map<String, dynamic>);
      }
      throw Exception('Failed to fetch warehouse: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading warehouse: ${_formatError(e)}');
    }
  }

  /// Get nearest warehouses with grain type
  /// Returns warehouses sorted by distance with available zones
  Future<List<Warehouse>> getNearestWarehouses({
    required double latitude,
    required double longitude,
    int? grainTypeId,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'lat': latitude,
        'lng': longitude,
        'limit': limit,
      };
      
      if (grainTypeId != null) {
        queryParams['grainType'] = grainTypeId;
      }

      final response = await apiService.get('/geolocation/nearest', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final warehousesData = data['data']['allWarehouses'] as List<dynamic>;
        return warehousesData
            .map((w) => Warehouse.fromJson(w as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to fetch nearest warehouses');
    } catch (e) {
      rethrow;
    }
  }

  /// Get storage zones for a warehouse
  /// - Warehouse admin can only see zones in their warehouse
  Future<List<StorageZone>> getWarehouseZones(int warehouseId) async {
    try {
      final response = await apiService.get(
        '/zone',
        queryParameters: {'warehouse_id': warehouseId},
      );
      
      if (response.statusCode == 200) {
        // Backend returns list directly
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);
        return data.map((z) => StorageZone.fromJson(z as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch zones: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading zones: ${_formatError(e)}');
    }
  }

  /// Get all grains
  Future<List<Grain>> getAllGrains() async {
    try {
      final response = await apiService.get('/grain');
      
      if (response.statusCode == 200) {
        // Backend returns list directly
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);
        return data.map((g) => Grain.fromJson(g as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch grains: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading grains: ${_formatError(e)}');
    }
  }

  /// Get grain by ID
  Future<Grain> getGrainById(int grainId) async {
    try {
      final response = await apiService.get('/grain/$grainId');
      
      if (response.statusCode == 200) {
        return Grain.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to fetch grain');
    } catch (e) {
      rethrow;
    }
  }

  /// Update warehouse location (admin/warehouse admin only)
  Future<void> updateWarehouseLocation({
    required int warehouseId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await apiService.put(
        '/geolocation/warehouse/$warehouseId/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update warehouse location');
      }
    } catch (e) {
      rethrow;
    }
  }
}
