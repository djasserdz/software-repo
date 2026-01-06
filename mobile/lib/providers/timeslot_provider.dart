import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/time_slot.dart';

class TimeSlotProvider extends ChangeNotifier {
  final ApiService _apiService;

  TimeSlotProvider(this._apiService);

  List<TimeSlot> _timeSlots = [];
  List<TimeSlot> _filteredTimeSlots = [];
  TimeSlot? _selectedTimeSlot;
  bool _isLoading = false;
  String? _error;
  int? _selectedZoneId;

  // Getters
  List<TimeSlot> get timeSlots => _filteredTimeSlots;
  TimeSlot? get selectedTimeSlot => _selectedTimeSlot;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedZoneId => _selectedZoneId;

  // Fetch time slots for a zone
  Future<void> fetchTimeSlots(int zoneId) async {
    _selectedZoneId = zoneId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(
        '/time/',
        queryParameters: {'zone_id': zoneId},
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data ?? [];
        final List<dynamic> slots = data is List ? data : [];
        _timeSlots = slots.map((s) => TimeSlot.fromJson(s as Map<String, dynamic>)).toList();
        _filteredTimeSlots = _timeSlots;
        _error = null;
      } else {
        _error = 'Failed to fetch time slots: ${response.statusCode}';
      }
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create time slot
  Future<bool> createTimeSlot({
    required int zoneId,
    required DateTime startAt,
    required DateTime endAt,
    required String status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/time/',
        data: {
          'zone_id': zoneId,
          'start_at': startAt.toIso8601String(),
          'end_at': endAt.toIso8601String(),
          'status': status,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (_selectedZoneId != null) {
          await fetchTimeSlots(_selectedZoneId!);
        }
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to create time slot';
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

  // Update time slot
  Future<bool> updateTimeSlot({
    required int timeId,
    int? zoneId,
    DateTime? startAt,
    DateTime? endAt,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (zoneId != null) data['zone_id'] = zoneId;
      if (startAt != null) data['start_at'] = startAt.toIso8601String();
      if (endAt != null) data['end_at'] = endAt.toIso8601String();
      if (status != null) data['status'] = status;

      final response = await _apiService.patch('/time/$timeId', data: data);

      if (response.statusCode == 200) {
        if (_selectedZoneId != null) {
          await fetchTimeSlots(_selectedZoneId!);
        }
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to update time slot';
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

  // Delete time slot
  Future<bool> deleteTimeSlot(int timeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.delete('/time/$timeId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _timeSlots.removeWhere((s) => s.timeId == timeId);
        _filteredTimeSlots.removeWhere((s) => s.timeId == timeId);
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to delete time slot';
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

  // Generate time slots for next day
  Future<Map<String, dynamic>> generateNextDay() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/time/generate');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = response.data ?? {};
        if (_selectedZoneId != null) {
          await fetchTimeSlots(_selectedZoneId!);
        }
        return {
          'success': true,
          'count': result['count'] ?? 0,
          'message': result['message'] ?? 'Time slots generated successfully',
        };
      } else {
        _error = response.data['detail'] ?? 'Failed to generate time slots';
        return {'success': false, 'message': _error};
      }
    } catch (e) {
      _error = _formatError(e);
      return {'success': false, 'message': _error};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate time slots for next week
  Future<Map<String, dynamic>> generateWeek() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/time/generate-week');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = response.data ?? {};
        if (_selectedZoneId != null) {
          await fetchTimeSlots(_selectedZoneId!);
        }
        return {
          'success': true,
          'count': result['count'] ?? 0,
          'message': result['message'] ?? 'Time slots generated successfully',
        };
      } else {
        _error = response.data['detail'] ?? 'Failed to generate time slots';
        return {'success': false, 'message': _error};
      }
    } catch (e) {
      _error = _formatError(e);
      return {'success': false, 'message': _error};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

