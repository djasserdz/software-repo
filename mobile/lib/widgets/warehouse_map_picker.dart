import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

typedef OnLocationSelected = void Function(double latitude, double longitude, String address);

class WarehouseMapPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final OnLocationSelected onLocationSelected;

  const WarehouseMapPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    required this.onLocationSelected,
  });

  @override
  State<WarehouseMapPicker> createState() => _WarehouseMapPickerState();
}

class _WarehouseMapPickerState extends State<WarehouseMapPicker> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  LatLng? selectedLocation;
  String? selectedAddress;
  bool isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      selectedAddress = widget.initialAddress;
      _addMarker(selectedLocation!);
    }
  }

  void _addMarker(LatLng position) {
    setState(() {
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('warehouse_location'),
          position: position,
          infoWindow: const InfoWindow(
            title: 'Warehouse Location',
            snippet: 'Tap to confirm',
          ),
        ),
      );
      selectedLocation = position;
    });
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    setState(() => isLoadingAddress = true);
    try {
      final List<geo.Placemark> placemarks =
          await geo.placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final geo.Placemark place = placemarks.first;
        final String address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}'
            .replaceAll(RegExp(r',\s*,'), ',')
            .replaceAll(RegExp(r',\s*$'), '')
            .trim();

        setState(() => selectedAddress = address.isEmpty ? 'Address not found' : address);
      }
    } catch (e) {
      setState(() => selectedAddress = 'Error getting address: $e');
      debugPrint('Error getting address: $e');
    } finally {
      setState(() => isLoadingAddress = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final LatLng currentLocation = LatLng(position.latitude, position.longitude);
      _addMarker(currentLocation);

      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 15),
      );

      await _getAddressFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
      debugPrint('Error getting current location: $e');
    }
  }

  void _onMapTapped(LatLng position) {
    _addMarker(position);
    mapController.animateCamera(
      CameraUpdate.newLatLng(position),
    );
    _getAddressFromCoordinates(position.latitude, position.longitude);
  }

  void _confirmLocation() {
    if (selectedLocation != null) {
      widget.onLocationSelected(
        selectedLocation!.latitude,
        selectedLocation!.longitude,
        selectedAddress ?? 'Address not available',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialCenter = selectedLocation ??
        const LatLng(31.0, 36.0); // Default center for Algeria/Tunisia region

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AppBar(
            title: const Text('Select Warehouse Location'),
            automaticallyImplyLeading: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _getCurrentLocation,
                tooltip: 'Use Current Location',
              ),
            ],
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: initialCenter,
                zoom: 10,
              ),
              markers: markers,
              onTap: _onMapTapped,
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedLocation != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Coordinates:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (isLoadingAddress)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (selectedAddress != null) ...[
                    const Text(
                      'Address:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      selectedAddress!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _confirmLocation,
                          child: const Text('Confirm Location'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ] else
                  Center(
                    child: Text(
                      'Tap on the map to select a location',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
