import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/warehouse_map_picker.dart';

class AdminWarehousesScreen extends StatefulWidget {
  const AdminWarehousesScreen({super.key});

  @override
  State<AdminWarehousesScreen> createState() => _AdminWarehousesScreenState();
}

class _AdminWarehousesScreenState extends State<AdminWarehousesScreen> {
  final searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _xFloatController = TextEditingController();
  final _yFloatController = TextEditingController();
  String selectedStatus = 'all';
  String? _selectedStatusForForm;
  int? _selectedManagerId;
  bool _showCreateDialog = false;
  bool _showEditDialog = false;
  int? _editingWarehouseId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      provider.fetchWarehouses();
      provider.fetchUsers(); // Load users for manager dropdown
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _xFloatController.dispose();
    _yFloatController.dispose();
    super.dispose();
  }

  void _openCreateDialog() {
    setState(() {
      _showCreateDialog = true;
      _nameController.clear();
      _locationController.clear();
      _xFloatController.clear();
      _yFloatController.clear();
      _selectedStatusForForm = 'active';
      _selectedManagerId = null;
    });
  }

  void _openEditDialog(warehouse) {
    setState(() {
      _showEditDialog = true;
      _editingWarehouseId = warehouse.warehouseId;
      _nameController.text = warehouse.name;
      _locationController.text = warehouse.location;
      _xFloatController.text = warehouse.xFloat.toString();
      _yFloatController.text = warehouse.yFloat.toString();
      _selectedStatusForForm = warehouse.status;
      _selectedManagerId = warehouse.managerId;
    });
  }

  void _closeDialogs() {
    setState(() {
      _showCreateDialog = false;
      _showEditDialog = false;
      _editingWarehouseId = null;
    });
  }

  Future<void> _createWarehouse() async {
    if (_nameController.text.isEmpty || 
        _locationController.text.isEmpty ||
        _xFloatController.text.isEmpty ||
        _yFloatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final xFloat = double.tryParse(_xFloatController.text);
    final yFloat = double.tryParse(_yFloatController.text);
    if (xFloat == null || yFloat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid coordinates')),
      );
      return;
    }

    final provider = Provider.of<AdminProvider>(context, listen: false);
    final success = await provider.createWarehouse(
      name: _nameController.text,
      location: _locationController.text,
      xFloat: xFloat,
      yFloat: yFloat,
      managerId: _selectedManagerId,
      status: _selectedStatusForForm ?? 'active',
    );

    if (success) {
      _closeDialogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Warehouse created successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.warehousesError ?? 'Failed to create warehouse')),
      );
    }
  }

  Future<void> _updateWarehouse() async {
    if (_editingWarehouseId == null || 
        _nameController.text.isEmpty || 
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    double? xFloat;
    double? yFloat;
    if (_xFloatController.text.isNotEmpty) {
      xFloat = double.tryParse(_xFloatController.text);
    }
    if (_yFloatController.text.isNotEmpty) {
      yFloat = double.tryParse(_yFloatController.text);
    }

    final provider = Provider.of<AdminProvider>(context, listen: false);
    final success = await provider.updateWarehouse(
      warehouseId: _editingWarehouseId!,
      name: _nameController.text,
      location: _locationController.text,
      xFloat: xFloat,
      yFloat: yFloat,
      managerId: _selectedManagerId,
      status: _selectedStatusForForm,
    );

    if (success) {
      _closeDialogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Warehouse updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.warehousesError ?? 'Failed to update warehouse')),
      );
    }
  }

  void _deleteWarehouse(int warehouseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Warehouse'),
        content: const Text('Are you sure you want to delete this warehouse?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<AdminProvider>(context, listen: false);
              final success = await provider.deleteWarehouse(warehouseId);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Warehouse deleted successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(provider.warehousesError ?? 'Failed to delete warehouse')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openMapPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => WarehouseMapPicker(
        initialLatitude: _yFloatController.text.isNotEmpty
            ? double.tryParse(_yFloatController.text)
            : null,
        initialLongitude: _xFloatController.text.isNotEmpty
            ? double.tryParse(_xFloatController.text)
            : null,
        initialAddress: _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
        onLocationSelected: (latitude, longitude, address) {
          setState(() {
            _yFloatController.text = latitude.toStringAsFixed(6);
            _xFloatController.text = longitude.toStringAsFixed(6);
            _locationController.text = address;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Warehouses'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.warehousesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredWarehouses = provider.warehouses;

          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: SearchField(
                      controller: searchController,
                      hintText: 'Search warehouses...',
                      onChanged: (value) {
                        if (value.isEmpty) {
                          provider.fetchWarehouses();
                        } else {
                          provider.searchWarehouses(value);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredWarehouses.isEmpty
                        ? const EmptyState(
                            icon: Icons.warehouse_outlined,
                            title: 'No Warehouses Found',
                            subtitle: 'Start by creating a new warehouse',
                          )
                        : ListView.builder(
                            itemCount: filteredWarehouses.length,
                            itemBuilder: (context, index) {
                              final warehouse = filteredWarehouses[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacing12,
                                  vertical: AppTheme.spacing8,
                                ),
                                child: CustomCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  warehouse.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  warehouse.location,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          StatusBadge(
                                            label: warehouse.status.toUpperCase(),
                                            status: warehouse.status,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              warehouse.location.isNotEmpty 
                                                  ? warehouse.location 
                                                  : 'Address not available',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppTheme.spacing12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          TextButton.icon(
                                            icon: const Icon(Icons.edit),
                                            label: const Text('Edit'),
                                            onPressed: () => _openEditDialog(warehouse),
                                          ),
                                          TextButton.icon(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                            onPressed: () => _deleteWarehouse(warehouse.warehouseId),
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
              // Create Warehouse Dialog
              if (_showCreateDialog)
                _buildWarehouseDialog(
                  title: 'Create Warehouse',
                  onSave: _createWarehouse,
                ),
              // Edit Warehouse Dialog
              if (_showEditDialog)
                _buildWarehouseDialog(
                  title: 'Edit Warehouse',
                  onSave: _updateWarehouse,
                ),
            ],
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

  Widget _buildWarehouseDialog({
    required String title,
    required VoidCallback onSave,
  }) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final warehouseAdmins = provider.warehouseAdmins;

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
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location/Address *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppTheme.spacing12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.location_on),
                  label: const Text('Select Location on Map'),
                  onPressed: () => _openMapPicker(context),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _xFloatController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude (X)',
                          border: OutlineInputBorder(),
                          helperText: 'Auto-filled from map',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: TextField(
                        controller: _yFloatController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude (Y)',
                          border: OutlineInputBorder(),
                          helperText: 'Auto-filled from map',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing12),
                DropdownButtonFormField<int?>(
                  value: _selectedManagerId,
                  decoration: const InputDecoration(
                    labelText: 'Warehouse Admin (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('None')),
                    ...warehouseAdmins.map((admin) => DropdownMenuItem<int?>(
                      value: admin.userId,
                      child: Text('${admin.name} (${admin.email})'),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedManagerId = value);
                  },
                ),
                const SizedBox(height: AppTheme.spacing12),
                DropdownButtonFormField<String>(
                  value: _selectedStatusForForm,
                  decoration: const InputDecoration(
                    labelText: 'Status *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatusForForm = value);
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
      },
    );
  }
}
