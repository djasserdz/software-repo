import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/grain.dart';

class GrainProvider extends ChangeNotifier {
  final ApiService _apiService;

  GrainProvider(this._apiService);

  List<Grain> _grains = [];
  List<Grain> _filteredGrains = [];
  Grain? _selectedGrain;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Grain> get grains => _filteredGrains;
  Grain? get selectedGrain => _selectedGrain;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all grains
  Future<void> fetchGrains() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/grain');
      if (response.statusCode == 200) {
        // Backend returns list directly
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);
        _grains = data.map((g) => Grain.fromJson(g as Map<String, dynamic>)).toList();
        _filteredGrains = _grains;
        _error = null;
      } else {
        _error = 'Failed to fetch grains: ${response.statusCode}';
      }
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create grain
  Future<bool> createGrain({
    required String name,
    required double price, // Price per ton
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/grain/',
        data: {
          'name': name,
          'price': price,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchGrains();
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to create grain';
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

  // Update grain
  Future<bool> updateGrain({
    required int grainId,
    String? name,
    double? price,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (price != null) data['price'] = price;

      final response = await _apiService.patch('/grain/$grainId', data: data);

      if (response.statusCode == 200) {
        await fetchGrains();
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to update grain';
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

  // Delete grain
  Future<bool> deleteGrain(int grainId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.delete('/grain/$grainId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _grains.removeWhere((g) => g.grainId == grainId);
        _filteredGrains.removeWhere((g) => g.grainId == grainId);
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to delete grain';
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

  // Search grains
  void searchGrains(String query) {
    if (query.isEmpty) {
      _filteredGrains = List.from(_grains);
    } else {
      _filteredGrains = _grains
          .where((grain) =>
              grain.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
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

