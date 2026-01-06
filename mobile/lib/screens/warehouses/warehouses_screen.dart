import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/warehouse_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<WarehouseProvider>(context, listen: false).fetchWarehouses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouses'),
        elevation: 1,
      ),
      body: Consumer<WarehouseProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchWarehouses(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find & Explore',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          'Discover available warehouses near you',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  // Search and Filter
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing12,
                    ),
                    child: SearchField(
                      hintText: 'Search warehouses...',
                      onChanged: (value) {
                        provider.searchWarehouses(value);
                      },
                      controller: _searchController,
                    ),
                  ),

                  // Sort and Filter Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing12,
                    ),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            provider.sortByDistance();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sorted by distance'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.location_on),
                          label: const Text('Sort by Distance'),
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.push('/warehouses/map');
                            },
                            icon: const Icon(Icons.map),
                            label: const Text('View Map'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        OutlinedButton.icon(
                          onPressed: () {
                            provider.clearFilters();
                            _searchController.clear();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                    ),
                    child: _buildContent(context, provider),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, WarehouseProvider provider) {
    if (provider.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing32),
        child: LoadingState(message: 'Loading warehouses...'),
      );
    }

    if (provider.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing32),
        child: EmptyState(
          title: 'Error Loading Warehouses',
          subtitle: provider.error,
          icon: Icons.error_outline,
          onRetry: () => provider.fetchWarehouses(),
          retryLabel: 'Retry',
        ),
      );
    }

    if (provider.filteredWarehouses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing32),
        child: EmptyState(
          title: 'No Warehouses Found',
          subtitle: 'Try adjusting your search or filters',
          icon: Icons.warehouse,
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: provider.filteredWarehouses.length,
      itemBuilder: (context, index) {
        final warehouse = provider.filteredWarehouses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
          child: _buildWarehouseCard(context, warehouse),
        );
      },
    );
  }

  Widget _buildWarehouseCard(BuildContext context, dynamic warehouse) {
    return CustomCard(
      onTap: () => context.push('/warehouses/${warehouse.warehouseId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with name and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  warehouse.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              StatusBadge(
                label: warehouse.status.toUpperCase(),
                status: warehouse.status,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),

          // Location
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: AppTheme.spacing6),
              Expanded(
                child: Text(
                  warehouse.location,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),

          // Address and Distance
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: AppTheme.spacing6),
              Expanded(
                child: Text(
                  warehouse.location.isNotEmpty 
                    ? warehouse.location 
                    : 'Address not available',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (warehouse.distance != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryExtraLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    '${warehouse.distance!.toStringAsFixed(2)} km',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),

          // Capacity Information (if available)
          if (warehouse.availableCapacity != null && warehouse.totalCapacity != null)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Capacity',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${warehouse.availableCapacity!.toStringAsFixed(0)} / ${warehouse.totalCapacity!.toStringAsFixed(0)} kg',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: warehouse.availableCapacity! / warehouse.totalCapacity!,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      warehouse.availableCapacity! / warehouse.totalCapacity! > 0.3
                          ? AppTheme.primaryColor
                          : AppTheme.warningColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
              ],
            ),

          // View Details Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  context.push('/warehouses/${warehouse.warehouseId}'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              ),
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }
}

