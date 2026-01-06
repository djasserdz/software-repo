import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../services/api_service.dart';

class AppointmentProvider with ChangeNotifier {
  final ApiService apiService;
  
  List<Appointment> _appointments = [];
  List<Appointment> _filteredAppointments = [];
  Appointment? _selectedAppointment;
  bool _isLoading = false;
  String? _error;
  String _statusFilter = '';

  AppointmentProvider(this.apiService);

  // Getters
  List<Appointment> get appointments => _appointments;
  List<Appointment> get filteredAppointments => _filteredAppointments;
  Appointment? get selectedAppointment => _selectedAppointment;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all appointments for current user
  Future<void> fetchAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📡 [Appointment] Fetching appointments...');
      final response = await apiService.get('/appointment/');
      if (response.statusCode == 200) {
        // Backend returns list directly, not wrapped in 'data'
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['data'] ?? response.data['appointments'] ?? []);
        _appointments = data.map((a) => Appointment.fromJson(a as Map<String, dynamic>)).toList();
        _filteredAppointments = _appointments;
        _error = null;
        print('✅ [Appointment] Loaded ${_appointments.length} appointments');
      } else {
        _error = 'Failed to fetch appointments (Status: ${response.statusCode})';
        print('❌ [Appointment] $_error');
      }
    } catch (e) {
      _error = _formatError(e);
      print('❌ [Appointment] Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch single appointment
  Future<void> fetchAppointmentById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📡 [Appointment] Fetching appointment #$id...');
      final response = await apiService.get('/appointment/$id');
      if (response.statusCode == 200) {
        // Backend returns object directly, not wrapped in 'data'
        final data = response.data is Map 
            ? response.data 
            : (response.data['data'] ?? {});
        _selectedAppointment = Appointment.fromJson(data as Map<String, dynamic>);
        _error = null;
        print('✅ [Appointment] Loaded appointment #$id');
      } else {
        _error = 'Failed to fetch appointment (Status: ${response.statusCode})';
        print('❌ [Appointment] $_error');
      }
    } catch (e) {
      _error = _formatError(e);
      print('❌ [Appointment] Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new appointment
  Future<bool> createAppointment({
    required int warehouseId,
    required int grainId,
    required String scheduledDate,
    required String scheduledTime,
    int? quantityBags,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.post(
        '/appointments',
        data: {
          'warehouse_id': warehouseId,
          'grain_id': grainId,
          'scheduled_date': scheduledDate,
          'scheduled_time': scheduledTime,
          'quantity_bags': quantityBags,
          'notes': notes,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchAppointments();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to create appointment';
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

  // Update appointment
  Future<bool> updateAppointment({
    required int appointmentId,
    String? status,
    String? scheduledDate,
    String? scheduledTime,
    int? quantityBags,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (status != null) data['status'] = status;
      if (scheduledDate != null) data['scheduled_date'] = scheduledDate;
      if (scheduledTime != null) data['scheduled_time'] = scheduledTime;
      if (quantityBags != null) data['quantity_bags'] = quantityBags;
      if (notes != null) data['notes'] = notes;

      final response = await apiService.put(
        '/appointments/$appointmentId',
        data: data,
      );

      if (response.statusCode == 200) {
        await fetchAppointments();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to update appointment';
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

  // Confirm appointment and update warehouse capacity
  Future<bool> confirmAppointment({
    required int appointmentId,
    required int warehouseId,
    required double quantityToReduce,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First, update appointment status to confirmed
      final appointmentResponse = await apiService.put(
        '/appointments/$appointmentId',
        data: {'status': 'confirmed'},
      );

      if (appointmentResponse.statusCode != 200) {
        _error = 'Failed to confirm appointment';
        return false;
      }

      // Then, update warehouse capacity
      try {
        await apiService.put(
          '/warehouses/$warehouseId/capacity',
          data: {
            'reduce_by': quantityToReduce,
          },
        );
      } catch (e) {
        // If capacity update fails, still consider the appointment confirmed
        // Log the error but don't fail the operation
        print('Warning: Failed to update warehouse capacity: $e');
      }

      // Fetch updated appointments
      await fetchAppointments();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel appointment
  Future<bool> cancelAppointment(int appointmentId) async {
    return updateAppointment(
      appointmentId: appointmentId,
      status: 'cancelled',
    );
  }

  // Accept appointment (warehouse admin)
  Future<bool> acceptAppointment(int appointmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.put('/appointment/$appointmentId/accept');
      if (response.statusCode == 200) {
        await fetchAppointments();
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to accept appointment';
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

  // Refuse appointment (warehouse admin)
  Future<bool> refuseAppointment(int appointmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.put('/appointment/$appointmentId/refuse');
      if (response.statusCode == 200) {
        await fetchAppointments();
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to refuse appointment';
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

  // Confirm attendance (warehouse admin)
  Future<bool> confirmAttendance(int appointmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.put('/appointment/$appointmentId/confirm-attendance');
      if (response.statusCode == 200) {
        await fetchAppointments();
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to confirm attendance';
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

  // Filter by status
  void filterByStatus(String status) {
    _statusFilter = status.toLowerCase();
    if (_statusFilter.isEmpty) {
      _filteredAppointments = _appointments;
    } else {
      _filteredAppointments = _appointments
          .where((a) => a.status.toLowerCase() == _statusFilter)
          .toList();
    }
    notifyListeners();
  }

  // Get recent appointments
  List<Appointment> getRecentAppointments({int limit = 5}) {
    final recent = List<Appointment>.from(_appointments);
    recent.sort((a, b) => (b.createdAt ?? DateTime(1)).compareTo(a.createdAt ?? DateTime(1)));
    return recent.take(limit).toList();
  }

  // Get appointment counts by status
  Map<String, int> getAppointmentStats() {
    return {
      'total': _appointments.length,
      'pending': _appointments.where((a) => a.status.toLowerCase() == 'pending').length,
      'confirmed': _appointments.where((a) => a.status.toLowerCase() == 'confirmed').length,
      'completed': _appointments.where((a) => a.status.toLowerCase() == 'completed').length,
      'cancelled': _appointments.where((a) => a.status.toLowerCase() == 'cancelled').length,
    };
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
