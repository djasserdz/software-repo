import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/zone_provider.dart';
import '../../providers/warehouse_provider.dart';
import '../../providers/grain_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class WarehouseAdminZonesScreen extends StatefulWidget {
  const WarehouseAdminZonesScreen({super.key});

  @override
  State<WarehouseAdminZonesScreen> createState() =>
      _WarehouseAdminZonesScreenState();
}

class _WarehouseAdminZonesScreenState extends State<WarehouseAdminZonesScreen> {
  final _nameController = TextEditingController();
  final _totalCapacityController = TextEditingController();
  final _availableCapacityController = TextEditingController();
  int? _selectedWarehouseId;
  int? _selectedGrainTypeId;
  String? _selectedStatus;
  bool _showCreateDialog = false;
  bool _showEditDialog = false;
  int? _editingZoneId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final zoneProvider = Provider.of<ZoneProvider>(context, listen: false);
      final warehouseProvider = Provider.of<WarehouseProvider>(context, listen: false);
      final grainProvider = Provider.of<GrainProvider>(context, listen: false);
      
      warehouseProvider.fetchWarehouses();
      grainProvider.fetchGrains();
      zoneProvider.fetchZones();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalCapacityController.dispose();
    _availableCapacityController.dispose();
    super.dispose();
  }

  void _openCreateDialog() {
    setState(() {
      _showCreateDialog = true;
      _nameController.clear();
      _totalCapacityController.clear();
      _availableCapacityController.clear();
      _selectedWarehouseId = null;
      _selectedGrainTypeId = null;
      _selectedStatus = 'active';
    });
  }

  void _openEditDialog(zone) {
    setState(() {
      _showEditDialog = true;
      _editingZoneId = zone.zoneId;
      _nameController.text = zone.name;
      _totalCapacityController.text = zone.totalCapacity.toString();
      _availableCapacityController.text = zone.availableCapacity.toString();
      _selectedWarehouseId = zone.warehouseId;
      _selectedGrainTypeId = zone.grainTypeId;
      _selectedStatus = zone.status;
    });
  }

  void _closeDialogs() {
    setState(() {
      _showCreateDialog = false;
      _showEditDialog = false;
      _editingZoneId = null;
    });
  }

  Future<void> _createZone() async {
    if (_nameController.text.isEmpty || 
        _selectedWarehouseId == null ||
        _selectedGrainTypeId == null ||
        _totalCapacityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final totalCapacity = int.tryParse(_totalCapacityController.text);
    if (totalCapacity == null || totalCapacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid capacity (in tons)')),
      );
      return;
    }

    final provider = Provider.of<ZoneProvider>(context, listen: false);
    final success = await provider.createZone(
      warehouseId: _selectedWarehouseId!,
      name: _nameController.text,
      grainTypeId: _selectedGrainTypeId!,
      totalCapacity: totalCapacity,
      status: _selectedStatus ?? 'active',
    );

    if (success) {
      _closeDialogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zone created successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to create zone')),
      );
    }
  }

  Future<void> _updateZone() async {
    if (_editingZoneId == null || 
        _nameController.text.isEmpty ||
        _totalCapacityController.text.isEmpty ||
        _availableCapacityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final totalCapacity = int.tryParse(_totalCapacityController.text);
    final availableCapacity = int.tryParse(_availableCapacityController.text);
    if (totalCapacity == null || totalCapacity <= 0 ||
        availableCapacity == null || availableCapacity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid capacity values (in tons)')),
      );
      return;
    }

    final provider = Provider.of<ZoneProvider>(context, listen: false);
    final success = await provider.updateZone(
      zoneId: _editingZoneId!,
      name: _nameController.text,
      grainTypeId: _selectedGrainTypeId,
      totalCapacity: totalCapacity,
      availableCapacity: availableCapacity,
      status: _selectedStatus,
    );

    if (success) {
      _closeDialogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zone updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to update zone')),
      );
    }
  }

  void _filterByWarehouse(int? warehouseId) {
    final provider = Provider.of<ZoneProvider>(context, listen: false);
    provider.filterZones(warehouseId: warehouseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Zones'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<ZoneProvider>(
        builder: (context, zoneProvider, _) {
          return Consumer<WarehouseProvider>(
            builder: (context, warehouseProvider, _) {
              return Consumer<GrainProvider>(
                builder: (context, grainProvider, _) {
          if (zoneProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (zoneProvider.error != null && zoneProvider.zones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(zoneProvider.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => zoneProvider.fetchZones(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final zones = zoneProvider.zones;
          final warehouses = warehouseProvider.warehouses;

          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: DropdownButtonFormField<int?>(
                      value: _selectedWarehouseId,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Warehouse',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('All Warehouses')),
                        ...warehouses.map((w) => DropdownMenuItem<int?>(
                          value: w.warehouseId,
                          child: Text(w.name),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedWarehouseId = value);
                        _filterByWarehouse(value);
                      },
                    ),
                  ),
                  Expanded(
                    child: zones.isEmpty
                        ? const EmptyState(
                            icon: Icons.storage_outlined,
                            title: 'No Zones Found',
                            subtitle: 'Start by creating a new storage zone',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppTheme.spacing12),
                            itemCount: zones.length,
                            itemBuilder: (context, index) {
                              final zone = zones[index];
                              final available = zone.availableCapacity;
                              final total = zone.totalCapacity;
                              final utilization = total > 0 ? ((total - available) / total * 100) : 0;
                              String grainName = 'Unknown Grain';
                              try {
                                grainName = grainProvider.grains
                                    .firstWhere((g) => g.grainId == zone.grainTypeId)
                                    .name;
                              } catch (e) {
                                if (grainProvider.grains.isNotEmpty) {
                                  grainName = grainProvider.grains.first.name;
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
                                child: CustomCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                zone.name,
                                                style: Theme.of(context).textTheme.titleMedium,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Grain: $grainName',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                          StatusBadge(
                                            label: zone.status.toUpperCase(),
                                            status: zone.status,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Capacity Usage'),
                                              Text('${utilization.toStringAsFixed(1)}%'),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                            child: LinearProgressIndicator(
                                              value: (utilization / 100).clamp(0.0, 1.0),
                                              minHeight: 8,
                                              backgroundColor: Colors.grey[300],
                                              valueColor: AlwaysStoppedAnimation(
                                                utilization > 80
                                                    ? AppTheme.errorColor
                                                    : AppTheme.successColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Used: ${(total - available) * 1000} kg'),
                                          Text('Available: ${available * 1000} kg'),
                                          Text('Total: ${total * 1000} kg'),
                                        ],
                                      ),
                                      const SizedBox(height: AppTheme.spacing12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          TextButton.icon(
                                            icon: const Icon(Icons.edit),
                                            label: const Text('Edit'),
                                            onPressed: () => _openEditDialog(zone),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              // Create Zone Dialog
              if (_showCreateDialog)
                _buildZoneDialog(
                  title: 'Create Storage Zone',
                  onSave: _createZone,
                  isEdit: false,
                  warehouses: warehouses,
                  grains: grainProvider.grains,
                ),
              // Edit Zone Dialog
              if (_showEditDialog)
                _buildZoneDialog(
                  title: 'Edit Storage Zone',
                  onSave: _updateZone,
                  isEdit: true,
                  warehouses: warehouses,
                  grains: grainProvider.grains,
                ),
            ],
          );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildZoneDialog({
    required String title,
    required VoidCallback onSave,
    required bool isEdit,
    required List warehouses,
    required List grains,
  }) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing16),
            if (!isEdit)
              DropdownButtonFormField<int>(
                value: _selectedWarehouseId,
                decoration: const InputDecoration(
                  labelText: 'Warehouse *',
                  border: OutlineInputBorder(),
                ),
                items: warehouses.map((w) => DropdownMenuItem<int>(
                  value: w.warehouseId,
                  child: Text(w.name),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedWarehouseId = value);
                },
              ),
            if (!isEdit) const SizedBox(height: AppTheme.spacing12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Zone Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            DropdownButtonFormField<int>(
              value: _selectedGrainTypeId,
              decoration: const InputDecoration(
                labelText: 'Grain Type *',
                border: OutlineInputBorder(),
              ),
              items: grains.map((g) => DropdownMenuItem<int>(
                value: g.grainId,
                child: Text(g.name),
              )).toList(),
              onChanged: (value) {
                setState(() => _selectedGrainTypeId = value);
              },
            ),
            const SizedBox(height: AppTheme.spacing12),
            TextField(
              controller: _totalCapacityController,
              decoration: const InputDecoration(
                labelText: 'Total Capacity (tons) *',
                border: OutlineInputBorder(),
                helperText: 'Enter capacity in tons',
              ),
              keyboardType: TextInputType.number,
            ),
            if (isEdit) ...[
              const SizedBox(height: AppTheme.spacing12),
              TextField(
                controller: _availableCapacityController,
                decoration: const InputDecoration(
                  labelText: 'Available Capacity (tons) *',
                  border: OutlineInputBorder(),
                  helperText: 'Enter available capacity in tons',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: AppTheme.spacing12),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'not_active', child: Text('Not Active')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
              },
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _closeDialogs,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppTheme.spacing8),
                ElevatedButton(
                  onPressed: onSave,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
