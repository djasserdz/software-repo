import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/warehouse.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _apiService;

  AdminProvider(this._apiService);

  // Users Management
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _usersLoading = false;
  String? _usersError;

  // Warehouses Management
  List<Warehouse> _warehouses = [];
  List<Warehouse> _filteredWarehouses = [];
  bool _warehousesLoading = false;
  String? _warehousesError;

  // Statistics
  int _totalUsers = 0;
  int _totalWarehouses = 0;
  int _totalAppointments = 0;
  int _totalDeliveries = 0;
  bool _statsLoading = false;

  // Getters
  List<User> get users => _filteredUsers;
  bool get usersLoading => _usersLoading;
  String? get usersError => _usersError;

  List<Warehouse> get warehouses => _filteredWarehouses;
  bool get warehousesLoading => _warehousesLoading;
  String? get warehousesError => _warehousesError;

  int get totalUsers => _totalUsers;
  int get totalWarehouses => _totalWarehouses;
  int get totalAppointments => _totalAppointments;
  int get totalDeliveries => _totalDeliveries;
  bool get statsLoading => _statsLoading;

  // Fetch all users
  Future<void> fetchUsers() async {
    _usersLoading = true;
    _usersError = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/users');
      if (response.statusCode == 200) {
        // Backend returns list directly
        final List<dynamic> usersData = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);
        _users = usersData.map((u) => User.fromJson(u as Map<String, dynamic>)).toList();
        _filteredUsers = List.from(_users);
      } else {
        _usersError = 'Failed to fetch users: ${response.statusCode}';
      }
    } catch (e) {
      _usersError = _formatError(e);
    } finally {
      _usersLoading = false;
      notifyListeners();
    }
  }

  // Get warehouse admins (for dropdown)
  List<User> get warehouseAdmins {
    return _users.where((u) => u.role.toLowerCase() == 'warehouse_admin').toList();
  }

  // Search users
  void searchUsers(String query) {
    if (query.isEmpty) {
      _filteredUsers = List.from(_users);
    } else {
      _filteredUsers = _users
          .where((user) =>
              user.name.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()) ||
              (user.phone?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    }
    notifyListeners();
  }

  // Filter users by role
  void filterUsersByRole(String role) {
    if (role.isEmpty) {
      _filteredUsers = List.from(_users);
    } else {
      _filteredUsers = _users.where((user) => user.role.toLowerCase() == role.toLowerCase()).toList();
    }
    notifyListeners();
  }

  // Delete user
  Future<bool> deleteUser(int userId) async {
    try {
      final response = await _apiService.delete('/users/$userId');
      if (response.statusCode == 200) {
        _users.removeWhere((u) => u.userId == userId);
        _filteredUsers.removeWhere((u) => u.userId == userId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _usersError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Fetch all warehouses
  Future<void> fetchWarehouses() async {
    _warehousesLoading = true;
    _warehousesError = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/warehouse');
      if (response.statusCode == 200) {
        // Backend returns list directly, not wrapped in 'data'
        final List<dynamic> warehousesData = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);
        _warehouses = warehousesData.map((w) => Warehouse.fromJson(w as Map<String, dynamic>)).toList();
        _filteredWarehouses = List.from(_warehouses);
      } else {
        _warehousesError = 'Failed to fetch warehouses: ${response.statusCode}';
      }
    } catch (e) {
      _warehousesError = _formatError(e);
    } finally {
      _warehousesLoading = false;
      notifyListeners();
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
      return 'Network error: ${error.toString()}';
    }
    return error.toString();
  }

  // Search warehouses
  void searchWarehouses(String query) {
    if (query.isEmpty) {
      _filteredWarehouses = List.from(_warehouses);
    } else {
      _filteredWarehouses = _warehouses
          .where((warehouse) =>
              warehouse.name.toLowerCase().contains(query.toLowerCase()) ||
              warehouse.location.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  // Filter warehouses by status
  void filterWarehousesByStatus(String status) {
    if (status.isEmpty || status == 'all') {
      _filteredWarehouses = List.from(_warehouses);
    } else {
      _filteredWarehouses = _warehouses.where((w) => w.status == status).toList();
    }
    notifyListeners();
  }

  // Fetch dashboard statistics
  Future<void> fetchStatistics() async {
    _statsLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/admin/statistics');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? {};
        _totalUsers = data['total_users'] ?? 0;
        _totalWarehouses = data['total_warehouses'] ?? 0;
        _totalAppointments = data['total_appointments'] ?? 0;
        _totalDeliveries = data['total_deliveries'] ?? 0;
      }
    } catch (e) {
      // Handle error silently for stats
      debugPrint('Error fetching statistics: $e');
    } finally {
      _statsLoading = false;
      notifyListeners();
    }
  }

  // Clear all filters
  void clearFilters() {
    _filteredUsers = List.from(_users);
    _filteredWarehouses = List.from(_warehouses);
    notifyListeners();
  }

  // Create user
  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    try {
      final response = await _apiService.post(
        '/user/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role.toLowerCase(),
          'phone': phone ?? '',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchUsers();
        return true;
      }
      _usersError = response.data['detail'] ?? 'Failed to create user';
      notifyListeners();
      return false;
    } catch (e) {
      _usersError = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  // Update user
  Future<bool> updateUser({
    required int userId,
    String? name,
    String? email,
    String? phone,
    String? role,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (role != null) data['role'] = role.toLowerCase();

      final response = await _apiService.patch('/users/$userId', data: data);
      if (response.statusCode == 200) {
        await fetchUsers();
        return true;
      }
      _usersError = response.data['detail'] ?? 'Failed to update user';
      notifyListeners();
      return false;
    } catch (e) {
      _usersError = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  // Create warehouse
  Future<bool> createWarehouse({
    required String name,
    required String location,
    required double xFloat,
    required double yFloat,
    int? managerId,
    String? status,
  }) async {
    try {
      final response = await _apiService.post(
        '/warehouse/',
        data: {
          'name': name,
          'location': location,
          'x_float': xFloat,
          'y_float': yFloat,
          'manager_id': managerId,
          'status': status ?? 'active',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchWarehouses();
        return true;
      }
      _warehousesError = response.data['detail'] ?? 'Failed to create warehouse';
      notifyListeners();
      return false;
    } catch (e) {
      _warehousesError = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  // Update warehouse
  Future<bool> updateWarehouse({
    required int warehouseId,
    String? name,
    String? location,
    double? xFloat,
    double? yFloat,
    int? managerId,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (location != null) data['location'] = location;
      if (xFloat != null) data['x_float'] = xFloat;
      if (yFloat != null) data['y_float'] = yFloat;
      if (managerId != null) data['manager_id'] = managerId;
      if (status != null) data['status'] = status;

      final response = await _apiService.patch('/warehouse/$warehouseId', data: data);
      if (response.statusCode == 200) {
        await fetchWarehouses();
        return true;
      }
      _warehousesError = response.data['detail'] ?? 'Failed to update warehouse';
      notifyListeners();
      return false;
    } catch (e) {
      _warehousesError = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  // Delete warehouse
  Future<bool> deleteWarehouse(int warehouseId) async {
    try {
      final response = await _apiService.delete('/warehouse/$warehouseId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _warehouses.removeWhere((w) => w.warehouseId == warehouseId);
        _filteredWarehouses.removeWhere((w) => w.warehouseId == warehouseId);
        notifyListeners();
        return true;
      }
      _warehousesError = 'Failed to delete warehouse';
      notifyListeners();
      return false;
    } catch (e) {
      _warehousesError = _formatError(e);
      notifyListeners();
      return false;
    }
  }
}
