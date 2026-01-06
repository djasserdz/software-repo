import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class WarehouseAdminDeliveriesScreen extends StatefulWidget {
  const WarehouseAdminDeliveriesScreen({super.key});

  @override
  State<WarehouseAdminDeliveriesScreen> createState() =>
      _WarehouseAdminDeliveriesScreenState();
}

class _WarehouseAdminDeliveriesScreenState
    extends State<WarehouseAdminDeliveriesScreen> {
  String selectedStatus = 'all';

  final deliveries = [
    {
      'id': 'DEL001',
      'appointment_id': 'AP001',
      'farmer_name': 'Ahmed Hassan',
      'grain': 'Wheat',
      'quantity': 500,
      'unit': 'kg',
      'zone': 'Zone A',
      'scheduled_date': '2024-01-20',
      'status': 'pending',
      'arrival_time': null,
    },
    {
      'id': 'DEL002',
      'appointment_id': 'AP002',
      'farmer_name': 'Fatima Ali',
      'grain': 'Barley',
      'quantity': 300,
      'unit': 'kg',
      'zone': 'Zone B',
      'scheduled_date': '2024-01-21',
      'status': 'in_progress',
      'arrival_time': '09:15 AM',
    },
    {
      'id': 'DEL003',
      'appointment_id': 'AP003',
      'farmer_name': 'Mohammed Ibrahim',
      'grain': 'Corn',
      'quantity': 750,
      'unit': 'kg',
      'zone': 'Zone C',
      'scheduled_date': '2024-01-19',
      'status': 'completed',
      'arrival_time': '10:30 AM',
    },
  ];

  List<Map<String, dynamic>> get filteredDeliveries {
    if (selectedStatus == 'all') return deliveries;
    return deliveries
        .where((del) => (del['status'] as String?) == selectedStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deliveries'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All',
                  value: 'all',
                  color: Colors.blue,
                ),
                const SizedBox(width: AppTheme.spacing8),
                _buildFilterChip(
                  label: 'Pending',
                  value: 'pending',
                  color: Colors.orange,
                ),
                const SizedBox(width: AppTheme.spacing8),
                _buildFilterChip(
                  label: 'In Progress',
                  value: 'in_progress',
                  color: Colors.amber,
                ),
                const SizedBox(width: AppTheme.spacing8),
                _buildFilterChip(
                  label: 'Completed',
                  value: 'completed',
                  color: Colors.green,
                ),
              ],
            ),
          ),
          // Deliveries list
          Expanded(
            child: filteredDeliveries.isEmpty
                ? const Center(
                    child: Text('No deliveries found'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12),
                    itemCount: filteredDeliveries.length,
                    itemBuilder: (context, index) {
                      final delivery = filteredDeliveries[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing8),
                        child: CustomCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with ID and status
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ID: ${delivery['id']}',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  StatusBadge(
                                    label: _getStatusLabel(
                                        delivery['status'] as String?),
                                    status: delivery['status'] as String? ??
                                        'pending',
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacing8),
                              // Farmer and grain
                              InfoRow(
                                label: 'Farmer',
                                value:
                                    delivery['farmer_name'] as String? ?? 'N/A',
                              ),
                              const SizedBox(height: AppTheme.spacing8),
                              // Grain details
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${delivery['grain']} - ${delivery['quantity']}${delivery['unit']}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacing8),
                              // Zone info
                              InfoRow(
                                label: 'Zone',
                                value: delivery['zone'] as String? ?? 'N/A',
                              ),
                              const SizedBox(height: AppTheme.spacing8),
                              // Scheduled date
                              InfoRow(
                                label: 'Scheduled',
                                value:
                                    delivery['scheduled_date'] as String? ??
                                        'N/A',
                              ),
                              if (delivery['status'] != 'pending')
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: AppTheme.spacing8),
                                  child: InfoRow(
                                    label: 'Arrival Time',
                                    value: delivery['arrival_time'] as String? ??
                                        'Not arrived',
                                  ),
                                ),
                              const SizedBox(height: AppTheme.spacing12),
                              // Action buttons
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('View'),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'View delivery ${delivery['id']} details')),
                                      );
                                    },
                                  ),
                                  if (delivery['status'] == 'pending')
                                    TextButton.icon(
                                      icon: const Icon(Icons.check_circle),
                                      label: const Text('Start'),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Delivery ${delivery['id']} started')),
                                        );
                                      },
                                    ),
                                  if (delivery['status'] == 'in_progress')
                                    TextButton.icon(
                                      icon: const Icon(Icons.done_all),
                                      label: const Text('Complete'),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Delivery ${delivery['id']} completed')),
                                        );
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required Color color,
  }) {
    final isSelected = selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedStatus = value;
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: color.withOpacity(0.3),
      side: BorderSide(
        color: isSelected ? color : Colors.grey[300]!,
      ),
    );
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'pending':
      default:
        return 'PENDING';
    }
  }
}
