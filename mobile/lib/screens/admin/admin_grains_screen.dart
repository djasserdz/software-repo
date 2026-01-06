import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/grain_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class AdminGrainsScreen extends StatefulWidget {
  const AdminGrainsScreen({super.key});

  @override
  State<AdminGrainsScreen> createState() => _AdminGrainsScreenState();
}

class _AdminGrainsScreenState extends State<AdminGrainsScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  bool _showCreateDialog = false;
  bool _showEditDialog = false;
  int? _editingGrainId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GrainProvider>(context, listen: false).fetchGrains();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _openCreateDialog() {
    setState(() {
      _showCreateDialog = true;
      _nameController.clear();
      _priceController.clear();
    });
  }

  void _openEditDialog(grain) {
    setState(() {
      _showEditDialog = true;
      _editingGrainId = grain.grainId;
      _nameController.text = grain.name;
      // Price is per ton, convert to DZD/kg for display
      _priceController.text = (grain.price / 1000).toStringAsFixed(2);
    });
  }

  void _closeDialogs() {
    setState(() {
      _showCreateDialog = false;
      _showEditDialog = false;
      _editingGrainId = null;
    });
  }

  Future<void> _createGrain() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final pricePerKg = double.tryParse(_priceController.text);
    if (pricePerKg == null || pricePerKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    // Convert price per kg to price per ton (backend expects per ton)
    final pricePerTon = pricePerKg * 1000;

    final provider = Provider.of<GrainProvider>(context, listen: false);
    final success = await provider.createGrain(
      name: _nameController.text,
      price: pricePerTon,
    );

    if (success) {
      _closeDialogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grain created successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to create grain')),
      );
    }
  }

  Future<void> _updateGrain() async {
    if (_editingGrainId == null || _nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final pricePerKg = double.tryParse(_priceController.text);
    if (pricePerKg == null || pricePerKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    // Convert price per kg to price per ton (backend expects per ton)
    final pricePerTon = pricePerKg * 1000;

    final provider = Provider.of<GrainProvider>(context, listen: false);
    final success = await provider.updateGrain(
      grainId: _editingGrainId!,
      name: _nameController.text,
      price: pricePerTon,
    );

    if (success) {
      _closeDialogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grain updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to update grain')),
      );
    }
  }

  void _deleteGrain(int grainId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Grain'),
        content: const Text('Are you sure you want to delete this grain?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<GrainProvider>(context, listen: false);
              final success = await provider.deleteGrain(grainId);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Grain deleted successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(provider.error ?? 'Failed to delete grain')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Grains'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<GrainProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.grains.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchGrains(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final grains = provider.grains;

          return Stack(
            children: [
              grains.isEmpty
                  ? const EmptyState(
                      icon: Icons.grass_outlined,
                      title: 'No Grains Found',
                      subtitle: 'Start by creating a new grain type',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.spacing12),
                      itemCount: grains.length,
                      itemBuilder: (context, index) {
                        final grain = grains[index];
                        final pricePerKg = grain.price / 1000;

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
                                          grain.name,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Price: ${_formatPrice(pricePerKg)} DZD/kg',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    StatusBadge(
                                      label: 'ACTIVE',
                                      status: 'active',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacing12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                      onPressed: () => _openEditDialog(grain),
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      label: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onPressed: () => _deleteGrain(grain.grainId),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              // Create Grain Dialog
              if (_showCreateDialog)
                _buildGrainDialog(
                  title: 'Create Grain',
                  onSave: _createGrain,
                ),
              // Edit Grain Dialog
              if (_showEditDialog)
                _buildGrainDialog(
                  title: 'Edit Grain',
                  onSave: _updateGrain,
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

  Widget _buildGrainDialog({
    required String title,
    required VoidCallback onSave,
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
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price per kg (DZD) *',
                border: OutlineInputBorder(),
                helperText: 'Enter price per kilogram',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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
