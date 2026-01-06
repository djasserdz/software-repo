import 'api_service.dart';
import '../models/appointment.dart';

class AppointmentService {
  final ApiService apiService;

  AppointmentService(this.apiService);

  /// Get all appointments
  /// - Admin: sees all appointments
  /// - WarehouseAdmin: sees only appointments for their warehouse's zones
  /// - Farmer: sees only their own appointments
  Future<List<Appointment>> getAllAppointments({
    int? zoneId,
    int? farmerId,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      
      if (zoneId != null) queryParams['zone_id'] = zoneId;
      if (farmerId != null) queryParams['farmer_id'] = farmerId;
      if (status != null) queryParams['status'] = status;

      final response = await apiService.get(
        '/appointment',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((a) => Appointment.fromJson(a as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch appointments');
    } catch (e) {
      rethrow;
    }
  }

  /// Get appointments for current farmer
  Future<List<Appointment>> getMyAppointments({String? status}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (status != null) queryParams['status'] = status;

      final response = await apiService.get(
        '/appointment/my-appointments',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> appointments = data['appointments'] ?? [];
        return appointments.map((a) => Appointment.fromJson(a as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch my appointments');
    } catch (e) {
      rethrow;
    }
  }

  /// Get appointment by ID
  /// - WarehouseAdmin can only see appointments for their warehouse
  Future<Appointment> getAppointmentById(int appointmentId) async {
    try {
      final response = await apiService.get('/appointment/$appointmentId');
      
      if (response.statusCode == 200) {
        return Appointment.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to fetch appointment');
    } catch (e) {
      rethrow;
    }
  }

  /// Create new appointment (farmer only)
  Future<Appointment> createAppointment({
    required int warehouseZoneId,
    required int grainTypeId,
    required int timeSlotId,
    required int requestedQuantity,
  }) async {
    try {
      final response = await apiService.post(
        '/appointment',
        data: {
          'warehouseZoneId': warehouseZoneId,
          'grainTypeId': grainTypeId,
          'timeSlotId': timeSlotId,
          'requestedQuantity': requestedQuantity,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Appointment.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to create appointment');
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel appointment (farmer only - own appointments)
  Future<void> cancelAppointment(int appointmentId) async {
    try {
      final response = await apiService.put(
        '/appointment/$appointmentId/cancel',
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to cancel appointment');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Accept appointment (warehouse admin only - their warehouse appointments)
  Future<void> acceptAppointment(int appointmentId) async {
    try {
      final response = await apiService.put(
        '/appointment/$appointmentId/accept',
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to accept appointment');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Refuse appointment (warehouse admin only - their warehouse appointments)
  Future<void> refuseAppointment(int appointmentId) async {
    try {
      final response = await apiService.put(
        '/appointment/$appointmentId/refuse',
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to refuse appointment');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Confirm attendance (warehouse admin only - their warehouse appointments)
  Future<void> confirmAttendance(int appointmentId) async {
    try {
      final response = await apiService.put(
        '/appointment/$appointmentId/confirm-attendance',
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to confirm attendance');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get appointment history (farmer only)
  Future<List<Appointment>> getAppointmentHistory() async {
    try {
      final response = await apiService.get('/appointment/history');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> appointments = data['appointments'] ?? [];
        return appointments.map((a) => Appointment.fromJson(a as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch appointment history');
    } catch (e) {
      rethrow;
    }
  }
}
