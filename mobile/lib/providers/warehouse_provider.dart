import 'package:flutter/foundation.dart';
import '../models/warehouse.dart';
import '../services/api_service.dart';

class WarehouseProvider with ChangeNotifier {
  final ApiService apiService;
  
  List<Warehouse> _warehouses = [];
  List<Warehouse> _filteredWarehouses = [];
  Warehouse? _selectedWarehouse;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  int? _selectedGrainType;

  WarehouseProvider(this.apiService);

  // Getters
  List<Warehouse> get warehouses => _warehouses;
  List<Warehouse> get filteredWarehouses => _filteredWarehouses;
  Warehouse? get selectedWarehouse => _selectedWarehouse;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int? get selectedGrainType => _selectedGrainType;

  // Fetch all warehouses
  Future<void> fetchWarehouses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/warehouse');
      if (response.statusCode == 200) {
        // Backend returns list directly, not wrapped in 'data'
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);
        _warehouses = data.map((w) => Warehouse.fromJson(w as Map<String, dynamic>)).toList();
        _filteredWarehouses = _warehouses;
        _error = null;
      } else {
        _error = 'Failed to fetch warehouses: ${response.statusCode}';
      }
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch single warehouse by ID
  Future<void> fetchWarehouseById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/warehouse/$id');
      if (response.statusCode == 200) {
        // Backend returns object directly, not wrapped in 'data'
        final data = response.data is Map 
            ? response.data 
            : (response.data['data'] ?? {});
        _selectedWarehouse = Warehouse.fromJson(data as Map<String, dynamic>);
        _error = null;
      } else {
        _error = 'Failed to fetch warehouse: ${response.statusCode}';
      }
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search warehouses
  void searchWarehouses(String query) {
    _searchQuery = query.toLowerCase();
    _filterWarehouses();
  }

  // Filter by grain type
  void filterByGrainType(int? grainTypeId) {
    _selectedGrainType = grainTypeId;
    _filterWarehouses();
  }

  // Apply filters
  void _filterWarehouses() {
    _filteredWarehouses = _warehouses.where((warehouse) {
      final matchesSearch = _searchQuery.isEmpty ||
          warehouse.name.toLowerCase().contains(_searchQuery) ||
          warehouse.location.toLowerCase().contains(_searchQuery);

      return matchesSearch;
    }).toList();

    notifyListeners();
  }

  // Sort warehouses by distance
  void sortByDistance() {
    _filteredWarehouses.sort((a, b) {
      final distA = a.distance ?? double.infinity;
      final distB = b.distance ?? double.infinity;
      return distA.compareTo(distB);
    });
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _selectedGrainType = null;
    _filteredWarehouses = _warehouses;
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
