import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/delivery_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<DeliveryProvider>(context, listen: false)
          .fetchDeliveries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deliveries'),
        elevation: 1,
      ),
      body: Consumer<DeliveryProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchDeliveries(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Status Filters
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Track Deliveries',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              StatusFilterChip(
                                label: 'All',
                                isSelected: _selectedStatus.isEmpty,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = '';
                                  });
                                  provider.filterByStatus('');
                                },
                              ),
                              const SizedBox(width: AppTheme.spacing8),
                              StatusFilterChip(
                                label: 'Pending',
                                isSelected: _selectedStatus == 'pending',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = 'pending';
                                  });
                                  provider.filterByStatus('pending');
                                },
                              ),
                              const SizedBox(width: AppTheme.spacing8),
                              StatusFilterChip(
                                label: 'In Transit',
                                isSelected: _selectedStatus == 'in_transit',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = 'in_transit';
                                  });
                                  provider.filterByStatus('in_transit');
                                },
                              ),
                              const SizedBox(width: AppTheme.spacing8),
                              StatusFilterChip(
                                label: 'Delivered',
                                isSelected: _selectedStatus == 'delivered',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = 'delivered';
                                  });
                                  provider.filterByStatus('delivered');
                                },
                              ),
                              const SizedBox(width: AppTheme.spacing8),
                              StatusFilterChip(
                                label: 'Failed',
                                isSelected: _selectedStatus == 'failed',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = 'failed';
                                  });
                                  provider.filterByStatus('failed');
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing12,
                    ),
                    child: _buildStatsRow(provider),
                  ),

                  // Deliveries List
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                    ),
                    child: _buildDeliveriesList(context, provider),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(DeliveryProvider provider) {
    final stats = provider.getDeliveryStats();
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard('Total', stats['total'].toString(), AppTheme.primaryColor),
          const SizedBox(width: AppTheme.spacing12),
          _buildStatCard('Pending', stats['pending'].toString(), AppTheme.warningColor),
          const SizedBox(width: AppTheme.spacing12),
          _buildStatCard('In Transit', stats['in_transit'].toString(), AppTheme.infoColor),
          const SizedBox(width: AppTheme.spacing12),
          _buildStatCard('Delivered', stats['delivered'].toString(), AppTheme.successColor),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      width: 90,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveriesList(
      BuildContext context, DeliveryProvider provider) {
    if (provider.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing32),
        child: LoadingState(message: 'Loading deliveries...'),
      );
    }

    if (provider.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing32),
        child: EmptyState(
          title: 'Error Loading Deliveries',
          subtitle: provider.error,
          icon: Icons.error_outline,
          onRetry: () => provider.fetchDeliveries(),
          retryLabel: 'Retry',
        ),
      );
    }

    if (provider.filteredDeliveries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing32),
        child: EmptyState(
          title: 'No Deliveries',
          subtitle: 'No deliveries to track at the moment',
          icon: Icons.local_shipping,
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: provider.filteredDeliveries.length,
      itemBuilder: (context, index) {
        final delivery = provider.filteredDeliveries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
          child: _buildDeliveryCard(context, delivery),
        );
      },
    );
  }

  Widget _buildDeliveryCard(BuildContext context, dynamic delivery) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery #${delivery.id}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      delivery.warehouseName ?? 'Warehouse',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: delivery.status.toUpperCase(),
                status: delivery.status,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Divider(
            height: 1,
            color: AppTheme.dividerColor,
            indent: 0,
            endIndent: 0,
          ),
          const SizedBox(height: AppTheme.spacing12),
          InfoRow(
            label: 'Delivery Date',
            value: delivery.deliveryDate,
          ),
          const SizedBox(height: AppTheme.spacing8),
          InfoRow(
            label: 'Quantity',
            value: '${delivery.actualDeliveredQuantity} units',
          ),
          if (delivery.grainName != null) ...[
            const SizedBox(height: AppTheme.spacing8),
            InfoRow(
              label: 'Grain Type',
              value: delivery.grainName ?? 'N/A',
            ),
          ],
          if (delivery.deliveryNotes != null && delivery.deliveryNotes!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    delivery.deliveryNotes!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Delivery #${delivery.id} details'),
                  ),
                );
              },
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }
}

