import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/timeslot_template.dart';

class TimeSlotTemplateProvider extends ChangeNotifier {
  final ApiService _apiService;

  TimeSlotTemplateProvider(this._apiService);

  List<TimeSlotTemplate> _templates = [];
  bool _isLoading = false;
  String? _error;

  List<TimeSlotTemplate> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all templates for a zone
  Future<void> fetchTemplatesByZone(int zoneId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/timeslot-template/zone/$zoneId');
      if (response.statusCode == 200) {
        final data = response.data;
        final templatesData = data is List ? data : (data['data'] ?? []);
        _templates = (templatesData as List)
            .map((t) => TimeSlotTemplate.fromJson(t as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Failed to fetch templates: ${response.statusCode}';
      }
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create template
  Future<bool> createTemplate({
    required int zoneId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    int maxAppointments = 1,
  }) async {
    try {
      final response = await _apiService.post(
        '/timeslot-template/',
        data: {
          'zone_id': zoneId,
          'day_of_week': dayOfWeek,
          'start_time': startTime,
          'end_time': endTime,
          'max_appointments': maxAppointments,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTemplatesByZone(zoneId);
        return true;
      }
      _error = response.data['detail'] ?? 'Failed to create template';
      notifyListeners();
      return false;
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  // Update template
  Future<bool> updateTemplate({
    required int templateId,
    required int zoneId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    int? maxAppointments,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (dayOfWeek != null) data['day_of_week'] = dayOfWeek;
      if (startTime != null) data['start_time'] = startTime;
      if (endTime != null) data['end_time'] = endTime;
      if (maxAppointments != null) data['max_appointments'] = maxAppointments;

      final response = await _apiService.patch('/timeslot-template/$templateId', data: data);

      if (response.statusCode == 200) {
        await fetchTemplatesByZone(zoneId);
        return true;
      }
      _error = response.data['detail'] ?? 'Failed to update template';
      notifyListeners();
      return false;
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  // Delete template
  Future<bool> deleteTemplate(int templateId, int zoneId) async {
    try {
      final response = await _apiService.delete('/timeslot-template/$templateId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _templates.removeWhere((t) => t.templateId == templateId);
        notifyListeners();
        return true;
      }
      _error = 'Failed to delete template';
      notifyListeners();
      return false;
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  String _formatError(dynamic error) {
    if (error.toString().contains('DioException') ||
        error.toString().contains('SocketException') ||
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
    return error.toString();
  }
}
