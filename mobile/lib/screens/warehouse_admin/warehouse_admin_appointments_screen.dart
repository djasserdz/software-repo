import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/warehouse_provider.dart';
import '../../providers/grain_provider.dart';
import '../../providers/zone_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class WarehouseAdminAppointmentsScreen extends StatefulWidget {
  const WarehouseAdminAppointmentsScreen({super.key});

  @override
  State<WarehouseAdminAppointmentsScreen> createState() =>
      _WarehouseAdminAppointmentsScreenState();
}

class _WarehouseAdminAppointmentsScreenState
    extends State<WarehouseAdminAppointmentsScreen> {
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppointmentProvider>(context, listen: false);
      provider.fetchAppointments();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  String _formatNumber(int num) {
    return NumberFormat('#,###').format(num);
  }

  String _getGrainName(int grainId, GrainProvider grainProvider) {
    try {
      final grain = grainProvider.grains.firstWhere((g) => g.grainId == grainId);
      return grain.name;
    } catch (e) {
      return 'Grain #$grainId';
    }
  }

  String _getZoneName(int zoneId, ZoneProvider zoneProvider) {
    try {
      final zone = zoneProvider.zones.firstWhere((z) => z.zoneId == zoneId);
      return zone.name;
    } catch (e) {
      return 'Zone #$zoneId';
    }
  }

  Future<void> _acceptAppointment(int appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Appointment'),
        content: const Text('Are you sure you want to accept this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<AppointmentProvider>(context, listen: false);
      final success = await provider.acceptAppointment(appointmentId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment accepted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to accept appointment')),
        );
      }
    }
  }

  Future<void> _refuseAppointment(int appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuse Appointment'),
        content: const Text('Are you sure you want to refuse this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Refuse',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<AppointmentProvider>(context, listen: false);
      final success = await provider.refuseAppointment(appointmentId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment refused')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to refuse appointment')),
        );
      }
    }
  }

  Future<void> _confirmAttendance(int appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Attendance'),
        content: const Text('Confirm that the farmer attended this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<AppointmentProvider>(context, listen: false);
      final success = await provider.confirmAttendance(appointmentId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance confirmed successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to confirm attendance')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, appointmentProvider, _) {
          return Consumer<WarehouseProvider>(
            builder: (context, warehouseProvider, _) {
              return Consumer<GrainProvider>(
                builder: (context, grainProvider, _) {
                  return Consumer<ZoneProvider>(
                    builder: (context, zoneProvider, _) {
          // Load related data
          if (grainProvider.grains.isEmpty) {
            grainProvider.fetchGrains();
          }
          if (zoneProvider.zones.isEmpty) {
            zoneProvider.fetchZones();
          }

          if (appointmentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appointmentProvider.error != null && appointmentProvider.appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(appointmentProvider.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => appointmentProvider.fetchAppointments(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Filter appointments by status
          List appointments = appointmentProvider.appointments;
          if (selectedStatus != null && selectedStatus != 'all') {
            appointments = appointments.where((a) => a.status.toLowerCase() == selectedStatus!.toLowerCase()).toList();
          }

          return Column(
            children: [
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(AppTheme.spacing12),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All', Colors.blue),
                    const SizedBox(width: AppTheme.spacing8),
                    _buildFilterChip('pending', 'Pending', Colors.orange),
                    const SizedBox(width: AppTheme.spacing8),
                    _buildFilterChip('accepted', 'Accepted', Colors.green),
                    const SizedBox(width: AppTheme.spacing8),
                    _buildFilterChip('completed', 'Completed', Colors.teal),
                    const SizedBox(width: AppTheme.spacing8),
                    _buildFilterChip('refused', 'Refused', Colors.grey),
                    const SizedBox(width: AppTheme.spacing8),
                    _buildFilterChip('cancelled', 'Cancelled', Colors.red),
                  ],
                ),
              ),
              // Appointments list
              Expanded(
                child: appointments.isEmpty
                    ? const EmptyState(
                        icon: Icons.calendar_today_outlined,
                        title: 'No Appointments Found',
                        subtitle: 'No appointments match the selected filter',
                      )
                    : RefreshIndicator(
                        onRefresh: () => appointmentProvider.fetchAppointments(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final appointment = appointments[index];

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
                              child: CustomCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Appointment #${appointment.appointmentId}',
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        StatusBadge(
                                          label: appointment.status.toUpperCase(),
                                          status: appointment.status,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppTheme.spacing8),
                                    InfoRow(
                                      label: 'Created',
                                      value: _formatDate(appointment.createdAt),
                                    ),
                                    const SizedBox(height: AppTheme.spacing8),
                                    InfoRow(
                                      label: 'Grain Type',
                                      value: _getGrainName(appointment.grainTypeId, grainProvider),
                                    ),
                                    const SizedBox(height: AppTheme.spacing8),
                                    InfoRow(
                                      label: 'Quantity',
                                      value: '${_formatNumber(appointment.requestedQuantity * 1000)} kg',
                                    ),
                                    const SizedBox(height: AppTheme.spacing8),
                                    InfoRow(
                                      label: 'Zone',
                                      value: _getZoneName(appointment.zoneId, zoneProvider),
                                    ),
                                    const SizedBox(height: AppTheme.spacing12),
                                    // Action buttons
                                    if (appointment.status.toLowerCase() == 'pending')
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.check, size: 18),
                                              label: const Text('Accept'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () => _acceptAppointment(appointment.appointmentId),
                                            ),
                                          ),
                                          const SizedBox(width: AppTheme.spacing8),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.close, size: 18),
                                              label: const Text('Refuse'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () => _refuseAppointment(appointment.appointmentId),
                                            ),
                                          ),
                                        ],
                                      )
                                    else if (appointment.status.toLowerCase() == 'accepted')
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.check_circle, size: 18),
                                          label: const Text('Confirm Attendance'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryColor,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () => _confirmAttendance(appointment.appointmentId),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedStatus = selected ? value : null;
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: color.withOpacity(0.3),
      side: BorderSide(
        color: isSelected ? color : Colors.grey[300]!,
      ),
    );
  }
}
