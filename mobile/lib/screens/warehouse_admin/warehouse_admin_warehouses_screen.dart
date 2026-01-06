import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../providers/warehouse_provider.dart';

class WarehouseAdminWarehousesScreen extends StatefulWidget {
  const WarehouseAdminWarehousesScreen({super.key});

  @override
  State<WarehouseAdminWarehousesScreen> createState() =>
      _WarehouseAdminWarehousesScreenState();
}

class _WarehouseAdminWarehousesScreenState
    extends State<WarehouseAdminWarehousesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WarehouseProvider>(context, listen: false).fetchWarehouses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Warehouses'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<WarehouseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.fetchWarehouses();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final warehouses = provider.warehouses;

          if (warehouses.isEmpty) {
            return const EmptyState(
              icon: Icons.warehouse_outlined,
              title: 'No Warehouses',
              subtitle: 'No warehouses assigned to you',
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchWarehouses(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              itemCount: warehouses.length,
              itemBuilder: (context, index) {
                final warehouse = warehouses[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
                  child: CustomCard(
                    onTap: () {
                      context.push('/warehouses/${warehouse.warehouseId}');
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with name and status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    warehouse.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    warehouse.location.isNotEmpty
                                        ? warehouse.location
                                        : 'Location not available',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 2,
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
                        const SizedBox(height: AppTheme.spacing12),
                        // Address
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                warehouse.location.isNotEmpty
                                    ? warehouse.location
                                    : 'Address not available',
                                style: Theme.of(context).textTheme.labelSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacing12),
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.layers),
                              label: const Text('Zones'),
                              onPressed: () {
                                context.push('/warehouse-admin/zones');
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('Appointments'),
                              onPressed: () {
                                context.push('/warehouse-admin/appointments');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
