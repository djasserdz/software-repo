import 'package:geocoding/geocoding.dart';
import 'api_service.dart';

class LocationService {
  final ApiService apiService;

  LocationService(this.apiService);

  /// Get address from coordinates using backend API
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final response = await apiService.get(
        '/location/coordinates/',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['display_name'] != null) {
          return data['display_name'] as String;
        } else if (data['address'] != null) {
          final addr = data['address'] as Map<String, dynamic>;
          final parts = <String>[];
          
          if (addr['road'] != null) parts.add(addr['road'] as String);
          if (addr['city'] != null) {
            parts.add(addr['city'] as String);
          } else if (addr['town'] != null) {
            parts.add(addr['town'] as String);
          } else if (addr['village'] != null) {
            parts.add(addr['village'] as String);
          }
          if (addr['state'] != null) {
            parts.add(addr['state'] as String);
          } else if (addr['region'] != null) {
            parts.add(addr['region'] as String);
          }
          if (addr['country'] != null) parts.add(addr['country'] as String);
          
          return parts.isNotEmpty ? parts.join(', ') : 'Address not available';
        }
      }
      return 'Address not available';
    } catch (e) {
      // Fallback to geocoding package if backend fails
      try {
        final placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = <String>[];
          if (place.street != null) parts.add(place.street!);
          if (place.locality != null) parts.add(place.locality!);
          if (place.administrativeArea != null) parts.add(place.administrativeArea!);
          if (place.country != null) parts.add(place.country!);
          return parts.isNotEmpty ? parts.join(', ') : 'Address not available';
        }
      } catch (_) {
        // If both fail, return coordinates as fallback
      }
      return 'Address not available';
    }
  }
}

