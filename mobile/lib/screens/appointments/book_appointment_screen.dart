import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/warehouse_service.dart';
import '../../models/grain.dart';
import '../../models/warehouse.dart';
import '../../models/storage_zone.dart';
import '../../models/time_slot.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final ApiService _apiService = ApiService();
  final WarehouseService _warehouseService = WarehouseService(ApiService());
  
  int _currentStep = 0;
  
  // Step 1: Grain & Quantity
  List<Grain> _grains = [];
  int? _selectedGrainTypeId;
  double? _requestedQuantityKg;
  final _quantityController = TextEditingController();
  bool _loadingGrains = false;
  
  // Step 2: Warehouse
  List<Warehouse> _warehouses = [];
  Warehouse? _selectedWarehouse;
  String _warehouseSearch = '';
  bool _loadingWarehouses = false;
  bool _loadingLocation = false;
  Position? _userPosition;
  
  // Step 3: Zone
  List<StorageZone> _availableZones = [];
  StorageZone? _selectedZone;
  bool _loadingZones = false;
  
  // Step 4: Time Slot
  List<TimeSlot> _availableTimeSlots = [];
  TimeSlot? _selectedTimeSlot;
  bool _loadingTimeSlots = false;
  bool _showCustomTime = false;
  bool _requestingCustomTime = false;
  String? _customTimeError;
  final _customDateController = TextEditingController();
  final _customStartTimeController = TextEditingController();
  final _customEndTimeController = TextEditingController();
  final _customNotesController = TextEditingController();
  TimeSlot? _customTimeSlot;
  
  // Booking
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGrains();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customDateController.dispose();
    _customStartTimeController.dispose();
    _customEndTimeController.dispose();
    _customNotesController.dispose();
    super.dispose();
  }

  // Step 1: Load Grains
  Future<void> _loadGrains() async {
    setState(() => _loadingGrains = true);
    try {
      _grains = await _warehouseService.getAllGrains();
    } catch (e) {
      _showError('Failed to load grain types: $e');
    } finally {
      setState(() => _loadingGrains = false);
    }
  }

  // Step 2: Load Warehouses
  Future<void> _loadWarehouses() async {
    if (_selectedGrainTypeId == null) return;
    
    setState(() {
      _loadingWarehouses = true;
      _warehouses = [];
      _error = null;
    });
    
    try {
      if (_userPosition != null) {
        // Load nearest warehouses filtered by grain type
        _warehouses = await _warehouseService.getNearestWarehouses(
          latitude: _userPosition!.latitude,
          longitude: _userPosition!.longitude,
          grainTypeId: _selectedGrainTypeId,
        );
      } else {
        // Load all warehouses first
        final allWarehouses = await _warehouseService.getAllWarehouses();
        
        // Filter warehouses that have zones with the selected grain type
        final warehousesWithGrain = <Warehouse>[];
        
        // Check each warehouse for zones with the selected grain type
        for (final warehouse in allWarehouses) {
          try {
            final zones = await _warehouseService.getWarehouseZones(warehouse.warehouseId);
            final hasGrainType = zones.any(
              (z) => z.grainTypeId == _selectedGrainTypeId && z.status == 'active'
            );
            if (hasGrainType) {
              warehousesWithGrain.add(warehouse);
            }
          } catch (e) {
            // Skip warehouses that fail to load zones
            continue;
          }
        }
        
        _warehouses = warehousesWithGrain;
        
        // If no results from manual filtering, try geolocation API with default location
        if (_warehouses.isEmpty && allWarehouses.isNotEmpty) {
          try {
            final defaultLat = 36.7538;
            final defaultLng = 3.0588;
            _warehouses = await _warehouseService.getNearestWarehouses(
              latitude: defaultLat,
              longitude: defaultLng,
              grainTypeId: _selectedGrainTypeId,
              limit: 100,
            );
          } catch (e) {
            // Silently fail if geolocation API is not available
          }
        }
      }
      
      if (_warehouses.isEmpty) {
        setState(() => _error = 'No warehouses found with the selected grain type');
      }
    } catch (e) {
      setState(() => _error = 'Failed to load warehouses: ${_formatError(e)}');
      _warehouses = [];
    } finally {
      setState(() => _loadingWarehouses = false);
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

  // Get user location
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
      await _loadWarehouses();
    } catch (e) {
      _showError('Failed to get location: $e');
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  // Step 3: Load Zones
  Future<void> _loadZones() async {
    if (_selectedWarehouse == null || _selectedGrainTypeId == null) return;
    
    setState(() {
      _loadingZones = true;
      _availableZones = [];
    });
    
    try {
      final zones = await _warehouseService.getWarehouseZones(_selectedWarehouse!.warehouseId);
      // Filter by grain type and available capacity
      // Backend stores capacity in tons, so convert kg to tons for comparison
      final requestedQuantityTons = (_requestedQuantityKg ?? 0) / 1000;
      _availableZones = zones
          .where((z) => 
              z.grainTypeId == _selectedGrainTypeId &&
              z.status == 'active' &&
              z.availableCapacity >= requestedQuantityTons)
          .toList();
      
      if (_availableZones.isEmpty) {
        setState(() => _error = 'No available zones with sufficient capacity for the requested quantity');
      }
    } catch (e) {
      _showError('Failed to load zones: $e');
    } finally {
      setState(() => _loadingZones = false);
    }
  }

  // Step 4: Load Time Slots
  Future<void> _loadTimeSlots() async {
    if (_selectedZone == null || _selectedGrainTypeId == null) return;
    
    setState(() {
      _loadingTimeSlots = true;
      _availableTimeSlots = [];
    });
    
    try {
      final response = await _apiService.get(
        '/time/available',
        queryParameters: {
          'zone_id': _selectedZone!.zoneId,
          'grain_type_id': _selectedGrainTypeId,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final slots = data['data'] ?? data ?? [];
        _availableTimeSlots = (slots as List)
            .map((s) => TimeSlot.fromJson(s as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _showError('Failed to load time slots: $e');
    } finally {
      setState(() => _loadingTimeSlots = false);
    }
  }

  // Request Custom Time Slot
  Future<void> _requestCustomTimeSlot() async {
    if (_customDateController.text.isEmpty ||
        _customStartTimeController.text.isEmpty ||
        _customEndTimeController.text.isEmpty ||
        _selectedZone == null) {
      setState(() => _customTimeError = 'Please fill all required fields');
      return;
    }

    setState(() {
      _requestingCustomTime = true;
      _customTimeError = null;
    });

    try {
      final date = _customDateController.text;
      final startTime = _customStartTimeController.text;
      final endTime = _customEndTimeController.text;
      
      final startDateTime = '$date ${startTime}:00';
      final endDateTime = '$date ${endTime}:00';

      final response = await _apiService.post(
        '/time/',
        data: {
          'zone_id': _selectedZone!.zoneId,
          'start_at': startDateTime,
          'end_at': endDateTime,
          'status': 'active',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _customTimeSlot = TimeSlot.fromJson(response.data as Map<String, dynamic>);
        _selectedTimeSlot = _customTimeSlot;
        setState(() => _showCustomTime = false);
        await _loadTimeSlots();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom time slot created successfully!')),
          );
        }
      }
    } catch (e) {
      setState(() => _customTimeError = 'Failed to create custom time slot: $e');
    } finally {
      setState(() => _requestingCustomTime = false);
    }
  }

  // Submit Booking
  Future<void> _submitBooking() async {
    if (_selectedGrainTypeId == null ||
        _requestedQuantityKg == null ||
        _requestedQuantityKg! <= 0 ||
        _selectedWarehouse == null ||
        _selectedZone == null ||
        (_selectedTimeSlot == null && _customTimeSlot == null)) {
      _showError('Please complete all steps');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final timeSlotId = _customTimeSlot?.timeId ?? _selectedTimeSlot?.timeId;
      if (timeSlotId == null) {
        setState(() => _error = 'Please select or request a time slot');
        setState(() => _submitting = false);
        return;
      }

      // Backend expects quantity in kg (as specified in the API model)
      final response = await _apiService.post(
        '/appointment/',
        data: {
          'grainTypeId': _selectedGrainTypeId,
          'warehouseZoneId': _selectedZone!.zoneId,
          'requestedQuantity': _requestedQuantityKg,
          'timeSlotId': timeSlotId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment booked successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _error = 'Failed to book appointment: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Failed to book appointment: ${_formatError(e)}');
      _showError(_error!);
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    setState(() => _error = message);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedGrainTypeId == null || _requestedQuantityKg == null || _requestedQuantityKg! <= 0) {
        _showError('Please select grain type and enter quantity');
        return;
      }
      _loadWarehouses();
    } else if (_currentStep == 1) {
      if (_selectedWarehouse == null) {
        _showError('Please select a warehouse');
        return;
      }
      _loadZones();
    } else if (_currentStep == 2) {
      if (_selectedZone == null) {
        _showError('Please select a zone');
        return;
      }
      _loadTimeSlots();
    }
    
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // Price calculations
  double _getGrainPricePerKg() {
    final grain = _grains.firstWhere((g) => g.grainId == _selectedGrainTypeId, orElse: () => Grain(grainId: 0, name: '', price: 0));
    return grain.price / 1000; // Convert from per ton to per kg
  }

  double _getEstimatedTotal() {
    if (_requestedQuantityKg == null || _selectedGrainTypeId == null) return 0;
    return _requestedQuantityKg! * _getGrainPricePerKg();
  }

  String _formatPrice(double price) {
    return NumberFormat('#,##0.00', 'ar_DZ').format(price);
  }

  String _formatNumber(double num) {
    return NumberFormat('#,##0', 'ar_DZ').format(num);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy', 'en_US').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm', 'en_US').format(date);
  }

  String _getDayName(DateTime date) {
    return DateFormat('EEEE', 'en_US').format(date);
  }

  String _getGrainName(int? grainId) {
    if (grainId == null) return 'Unknown';
    final grain = _grains.firstWhere((g) => g.grainId == grainId, orElse: () => Grain(grainId: 0, name: 'Unknown', price: 0));
    return grain.name;
  }

  List<Warehouse> get _filteredWarehouses {
    if (_warehouseSearch.isEmpty) return _warehouses;
    final query = _warehouseSearch.toLowerCase();
    return _warehouses.where((w) =>
        w.name.toLowerCase().contains(query) ||
        w.location.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          // Progress Steps
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                _buildStepIndicator(0, 'Grain & Quantity'),
                Expanded(child: _buildStepConnector(0)),
                _buildStepIndicator(1, 'Warehouse'),
                Expanded(child: _buildStepConnector(1)),
                _buildStepIndicator(2, 'Zone'),
                Expanded(child: _buildStepConnector(2)),
                _buildStepIndicator(3, 'Time Slot'),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Grain Type & Quantity
                  if (_currentStep == 0) _buildStep1(),
                  
                  // Step 2: Choose Warehouse
                  if (_currentStep == 1) _buildStep2(),
                  
                  // Step 3: Choose Zone
                  if (_currentStep == 2) _buildStep3(),
                  
                  // Step 4: Choose Time Slot
                  if (_currentStep == 3) _buildStep4(),
                  
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  
                  // Navigation Buttons
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        OutlinedButton(
                          onPressed: _previousStep,
                          child: const Text('Previous'),
                        )
                      else
                        const SizedBox(),
                      ElevatedButton(
                        onPressed: _currentStep == 3 ? _submitBooking : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: Text(
                          _currentStep == 3
                              ? (_submitting ? 'Booking...' : 'Complete Booking')
                              : 'Next',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppTheme.primaryColor
                : isActive
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : Colors.grey[300],
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isCompleted
                  ? AppTheme.primaryColor
                  : Colors.grey[400]!,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? AppTheme.primaryColor : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive || isCompleted
                ? AppTheme.primaryColor
                : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int step) {
    final isCompleted = _currentStep > step;
    return Container(
      height: 2,
      color: isCompleted ? AppTheme.primaryColor : Colors.grey[300],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Select Grain Type & Quantity',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Choose the type of grain and quantity you want to deliver'),
        const SizedBox(height: 24),
        
        // Grain Type
        const Text('Grain Type *', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _loadingGrains
            ? const CircularProgressIndicator()
            : DropdownButtonFormField<int>(
                value: _selectedGrainTypeId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                hint: const Text('Select grain type'),
                items: _grains.map((grain) {
                  final pricePerKg = grain.price / 1000;
                  return DropdownMenuItem(
                    value: grain.grainId,
                    child: Text('${grain.name} - ${_formatPrice(pricePerKg)} DZD/kg'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedGrainTypeId = value);
                },
              ),
        
        const SizedBox(height: 24),
        
        // Quantity
        const Text('Quantity (kg) *', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter quantity in kilograms',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _requestedQuantityKg = double.tryParse(value);
            });
          },
        ),
        
        // Estimated Cost
        if (_selectedGrainTypeId != null && _requestedQuantityKg != null && _requestedQuantityKg! > 0) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Cost',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quantity:'),
                    Text('${_formatNumber(_requestedQuantityKg!)} kg'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Price per kg:'),
                    Text('${_formatPrice(_getGrainPricePerKg())} DZD'),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${_formatPrice(_getEstimatedTotal())} DZD',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Choose Warehouse',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Select a warehouse from the list below'),
        const SizedBox(height: 24),
        
        // Location and Search
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search warehouses...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() => _warehouseSearch = value);
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _loadingLocation ? null : _getUserLocation,
              icon: const Icon(Icons.location_on),
              label: Text(_loadingLocation ? 'Loading...' : 'My Location'),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Warehouse List
        if (_loadingWarehouses)
          const Center(child: CircularProgressIndicator())
        else if (_filteredWarehouses.isEmpty)
          const Center(child: Text('No warehouses found'))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredWarehouses.length,
            itemBuilder: (context, index) {
              final warehouse = _filteredWarehouses[index];
              final isSelected = _selectedWarehouse?.warehouseId == warehouse.warehouseId;
              
              return CustomCard(
                onTap: () {
                  setState(() => _selectedWarehouse = warehouse);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.white,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              warehouse.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (warehouse.distance != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${warehouse.distance!.toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        warehouse.location,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3: Choose Storage Zone',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Select a storage zone from the selected warehouse'),
        const SizedBox(height: 24),
        
        if (_selectedWarehouse != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selected Warehouse:', style: TextStyle(fontSize: 12)),
                Text(
                  _selectedWarehouse!.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 24),
        
        if (_loadingZones)
          const Center(child: CircularProgressIndicator())
        else if (_availableZones.isEmpty)
          const Center(child: Text('No available zones for this grain type'))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _availableZones.length,
            itemBuilder: (context, index) {
              final zone = _availableZones[index];
              final isSelected = _selectedZone?.zoneId == zone.zoneId;
              // Backend stores capacity in tons, convert kg to tons
              final requestedQuantityTons = (_requestedQuantityKg ?? 0) / 1000;
              final exceedsCapacity = requestedQuantityTons > zone.availableCapacity;
              
              return CustomCard(
                onTap: () {
                  setState(() => _selectedZone = zone);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.white,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              zone.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          StatusBadge(
                            label: zone.status.toUpperCase(),
                            status: zone.status,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Grain: ${_getGrainName(zone.grainTypeId)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Available: ${_formatNumber(zone.availableCapacity * 1000)} / ${_formatNumber(zone.totalCapacity * 1000)} kg',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Used: ${_formatNumber((zone.totalCapacity - zone.availableCapacity) * 1000)} kg',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: zone.capacityPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          zone.capacityPercentage > 80
                              ? Colors.red
                              : zone.capacityPercentage > 50
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                      ),
                      if (exceedsCapacity) ...[
                        const SizedBox(height: 4),
                        Text(
                          '⚠️ Exceeds capacity',
                          style: TextStyle(fontSize: 10, color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 4: Choose Time Slot',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Select an available time slot for your delivery'),
        const SizedBox(height: 24),
        
        // Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Warehouse:', style: TextStyle(fontSize: 12)),
                        Text('Zone:', style: TextStyle(fontSize: 12)),
                        Text('Grain Type:', style: TextStyle(fontSize: 12)),
                        Text('Quantity:', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _selectedWarehouse?.name ?? 'N/A',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _selectedZone?.name ?? 'N/A',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _getGrainName(_selectedGrainTypeId),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_formatNumber(_requestedQuantityKg ?? 0)} kg',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Toggle between available slots and custom time
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _showCustomTime = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: !_showCustomTime
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Available Slots',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: !_showCustomTime
                          ? AppTheme.primaryColor
                          : Colors.grey[600],
                      fontWeight: !_showCustomTime
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _showCustomTime = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _showCustomTime
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Request Custom Time',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _showCustomTime
                          ? AppTheme.primaryColor
                          : Colors.grey[600],
                      fontWeight: _showCustomTime
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Available Time Slots or Custom Time Form
        if (!_showCustomTime) _buildAvailableTimeSlots() else _buildCustomTimeForm(),
      ],
    );
  }

  Widget _buildAvailableTimeSlots() {
    if (_loadingTimeSlots) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_availableTimeSlots.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Text('No available time slots for this zone.'),
            const SizedBox(height: 8),
            const Text(
              'You can request a custom time slot using the "Request Custom Time" tab above.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Found ${_availableTimeSlots.length} available time slot${_availableTimeSlots.length != 1 ? 's' : ''}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: _availableTimeSlots.length,
          itemBuilder: (context, index) {
            final slot = _availableTimeSlots[index];
            final isSelected = _selectedTimeSlot?.timeId == slot.timeId;
            
            return CustomCard(
              onTap: () {
                setState(() => _selectedTimeSlot = slot);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.white,
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDate(slot.startAt),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatTime(slot.startAt)} - ${_formatTime(slot.endAt)}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDayName(slot.startAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomTimeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Request a custom time slot: Choose your preferred date and time. The warehouse admin will review and confirm your request.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 24),
        
        // Date
        const Text('Preferred Date *', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _customDateController,
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now().add(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              _customDateController.text = DateFormat('yyyy-MM-dd').format(date);
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Start Time
        const Text('Preferred Start Time *', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _customStartTimeController,
          decoration: InputDecoration(
            hintText: 'HH:MM',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            suffixIcon: const Icon(Icons.access_time),
          ),
          readOnly: true,
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              _customStartTimeController.text =
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // End Time
        const Text('Preferred End Time *', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _customEndTimeController,
          decoration: InputDecoration(
            hintText: 'HH:MM',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            suffixIcon: const Icon(Icons.access_time),
          ),
          readOnly: true,
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              _customEndTimeController.text =
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Notes
        const Text('Notes (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _customNotesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any special requirements or notes...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        ),
        
        if (_customTimeError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _customTimeError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
        
        const SizedBox(height: 24),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _requestingCustomTime ? null : _requestCustomTimeSlot,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(_requestingCustomTime ? 'Requesting...' : 'Request This Time Slot'),
          ),
        ),
      ],
    );
  }
}
