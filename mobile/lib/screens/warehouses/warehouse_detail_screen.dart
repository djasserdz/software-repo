import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/warehouse_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class WarehouseDetailScreen extends StatefulWidget {
  final int warehouseId;

  const WarehouseDetailScreen({super.key, required this.warehouseId});

  @override
  State<WarehouseDetailScreen> createState() => _WarehouseDetailScreenState();
}

class _WarehouseDetailScreenState extends State<WarehouseDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch warehouse details when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WarehouseProvider>(context, listen: false)
          .fetchWarehouseById(widget.warehouseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Restrict farmers from viewing warehouse details
        if (authProvider.isFarmer) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Warehouse Details'),
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              leading: const BackButton(),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    Text(
                      'Access Restricted',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    const Text(
                      'You do not have permission to view warehouse details. '
                      'Please contact the administrator for access.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Warehouse Details'),
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            leading: const BackButton(),
          ),
          body: Consumer<WarehouseProvider>(
            builder: (context, warehouseProvider, _) {
              if (warehouseProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final warehouses = warehouseProvider.warehouses
                  .where((w) => w.warehouseId == widget.warehouseId)
                  .toList();

              if (warehouses.isEmpty) {
                return const Center(
                  child: Text('Warehouse not found'),
                );
              }

              final warehouse = warehouses.first;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Card with Address
                    Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 50,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Warehouse Location',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Address Display
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Column(
                                    children: [
                                      if (warehouse.street != null)
                                        Text(
                                          warehouse.street!,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      if (warehouse.street != null)
                                        const SizedBox(height: 4),
                                      if (warehouse.city != null ||
                                          warehouse.state != null ||
                                          warehouse.zipCode != null)
                                        Text(
                                          '${warehouse.city ?? ''}, ${warehouse.state ?? ''} ${warehouse.zipCode ?? ''}'
                                              .trim(),
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Warehouse info
                          CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Warehouse Information',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: AppTheme.spacing16),
                                InfoRow(
                                  label: 'Name',
                                  value: warehouse.name,
                                ),
                                const SizedBox(height: AppTheme.spacing12),
                                InfoRow(
                                  label: 'Location',
                                  value: warehouse.location,
                                ),
                                const SizedBox(height: AppTheme.spacing12),
                                InfoRow(
                                  label: 'Status',
                                  value: warehouse.status.toUpperCase(),
                                ),
                                const SizedBox(height: AppTheme.spacing12),
                                InfoRow(
                                  label: 'Manager ID',
                                  value: warehouse.managerId?.toString() ?? 'N/A',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing20),

                          // Storage zones section
                          SectionHeader(
                            title: 'Storage Zones',
                            subtitle: 'Available zones in this warehouse',
                          ),
                          const SizedBox(height: AppTheme.spacing12),

                          // Zones list placeholder
                          CustomCard(
                            child: Column(
                              children: [
                                ListItemTile(
                                  leading: Icon(
                                    Icons.inbox,
                                    color: AppTheme.primaryColor,
                                  ),
                                  title: 'View Storage Zones',
                                  subtitle: 'Browse available storage areas',
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    // Navigate to zones
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing20),

                          // Actions
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to book appointment
                                Navigator.pushNamed(
                                  context,
                                  '/book-appointment',
                                  arguments: {
                                    'warehouseId': warehouse.warehouseId
                                  },
                                );
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('Book Appointment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spacing16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
