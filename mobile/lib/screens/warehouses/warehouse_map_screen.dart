import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/warehouse_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/warehouse.dart';

class WarehouseMapScreen extends StatefulWidget {
  const WarehouseMapScreen({super.key});

  @override
  State<WarehouseMapScreen> createState() => _WarehouseMapScreenState();
}

class _WarehouseMapScreenState extends State<WarehouseMapScreen> {
  late GoogleMapController mapController;
  Position? _userPosition;
  Set<Marker> _markers = {};
  bool _loadingLocation = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWarehouses();
    });
  }

  Future<void> _getUserLocation() async {
    setState(() => _loadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied');
        return;
      }

      _userPosition = await Geolocator.getCurrentPosition();
      
      if (mounted && _mapReady) {
        try {
          mapController.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(
                  _userPosition!.latitude - 0.1,
                  _userPosition!.longitude - 0.1,
                ),
                northeast: LatLng(
                  _userPosition!.latitude + 0.1,
                  _userPosition!.longitude + 0.1,
                ),
              ),
              100,
            ),
          );
        } catch (e) {
          debugPrint('Map animation error: $e');
        }
      }
    } catch (e) {
      _showError('Failed to get location: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _loadWarehouses() async {
    final provider = Provider.of<WarehouseProvider>(context, listen: false);
    await provider.fetchWarehouses();

    _buildMarkers(provider.warehouses);
  }

  void _buildMarkers(List<Warehouse> warehouses) {
    final newMarkers = <Marker>{};

    for (final warehouse in warehouses) {
      final marker = Marker(
        markerId: MarkerId('warehouse_${warehouse.warehouseId}'),
        position: LatLng(warehouse.yFloat, warehouse.xFloat),
        infoWindow: InfoWindow(
          title: warehouse.name,
          snippet: warehouse.location,
          onTap: () => _showWarehouseDetails(warehouse),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        ),
      );
      newMarkers.add(marker);
    }

    // Add user location marker
    if (_userPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    setState(() => _markers = newMarkers);
  }

  void _showWarehouseDetails(Warehouse warehouse) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              warehouse.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(warehouse.location),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Status: ${warehouse.status.toUpperCase()}'),
              ],
            ),
            if (warehouse.distance != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.near_me, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('${warehouse.distance!.toStringAsFixed(2)} km away'),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, warehouse);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Map'),
        backgroundColor: AppTheme.primaryColor,
        leading: const BackButton(),
        actions: [
          if (_loadingLocation)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getUserLocation,
              tooltip: 'My Location',
            ),
        ],
      ),
      body: Consumer<WarehouseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                  _mapReady = true;
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(36.7538, 3.0588), // Algiers center
                  zoom: 12,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                compassEnabled: true,
                zoomControlsEnabled: true,
              ),
              // Legend/Info Box
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Warehouses', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Your Location', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Warehouse Count
              if (provider.warehouses.isNotEmpty)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      '${provider.warehouses.length} warehouse${provider.warehouses.length != 1 ? 's' : ''} found',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    try {
      if (_mapReady) {
        mapController.dispose();
      }
    } catch (e) {
      debugPrint('Error disposing map controller: $e');
    }
    super.dispose();
  }
}
