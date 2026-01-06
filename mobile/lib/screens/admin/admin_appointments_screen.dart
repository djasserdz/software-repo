import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  String selectedStatus = 'all';

  final appointments = [
    {
      'id': 1,
      'farmer': 'Ahmed Mohammed',
      'grain': 'Wheat',
      'quantity': 5000,
      'status': 'pending',
    },
    {
      'id': 2,
      'farmer': 'Fatima Ali',
      'grain': 'Barley',
      'quantity': 3500,
      'status': 'confirmed',
    },
    {
      'id': 3,
      'farmer': 'Omar Hassan',
      'grain': 'Corn',
      'quantity': 7200,
      'status': 'completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Appointments'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('pending', 'Pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('confirmed', 'Confirmed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('completed', 'Completed'),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appt = appointments[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
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
                                  'Appointment #${appt['id']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  appt['farmer'] as String,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            StatusBadge(
                              label: (appt['status'] as String).toUpperCase(),
                              status: appt['status'] as String,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacing12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Grain: ${appt['grain']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Quantity: ${appt['quantity']} kg',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacing12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.visibility),
                              label: const Text('View'),
                              onPressed: () {
                                // TODO: View appointment details
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.green),
                              label: const Text('Confirm',
                                  style: TextStyle(color: Colors.green)),
                              onPressed: () {
                                // TODO: Confirm appointment
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

  Widget _buildFilterChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: selectedStatus == value,
      onSelected: (selected) {
        setState(() => selectedStatus = value);
      },
    );
  }
}

