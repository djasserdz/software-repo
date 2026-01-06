import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/appointment_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AppointmentProvider>(context, listen: false)
          .fetchAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/appointments/book'),
            tooltip: 'Book Appointment',
          ),
        ],
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchAppointments(),
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
                          'My Appointments',
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
                                label: 'Confirmed',
                                isSelected: _selectedStatus == 'confirmed',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = 'confirmed';
                                  });
                                  provider.filterByStatus('confirmed');
                                },
                              ),
                              const SizedBox(width: AppTheme.spacing8),
                              StatusFilterChip(
                                label: 'Completed',
                                isSelected: _selectedStatus == 'completed',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = 'completed';
                                  });
                                  provider.filterByStatus('completed');
                                },
                              ),
                              const SizedBox(width: AppTheme.spacing8),
                              StatusFilterChip(
                                label: 'Cancelled',
                                isSelected: _selectedStatus == 'cancelled',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = 'cancelled';
                                  });
                                  provider.filterByStatus('cancelled');
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

                  // Appointments List
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                    ),
                    child: _buildAppointmentsList(context, provider),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/appointments/book'),
        icon: const Icon(Icons.add),
        label: const Text('Book Appointment'),
      ),
    );
  }

  Widget _buildStatsRow(AppointmentProvider provider) {
    final stats = provider.getAppointmentStats();
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard('Total', stats['total'].toString(), AppTheme.primaryColor),
          const SizedBox(width: AppTheme.spacing12),
          _buildStatCard('Pending', stats['pending'].toString(), AppTheme.warningColor),
          const SizedBox(width: AppTheme.spacing12),
          _buildStatCard('Confirmed', stats['confirmed'].toString(), AppTheme.infoColor),
          const SizedBox(width: AppTheme.spacing12),
          _buildStatCard('Completed', stats['completed'].toString(), AppTheme.successColor),
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

  Widget _buildAppointmentsList(
      BuildContext context, AppointmentProvider provider) {
    if (provider.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing32),
        child: LoadingState(message: 'Loading appointments...'),
      );
    }

    if (provider.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing32),
        child: EmptyState(
          title: 'Error Loading Appointments',
          subtitle: provider.error,
          icon: Icons.error_outline,
          onRetry: () => provider.fetchAppointments(),
          retryLabel: 'Retry',
        ),
      );
    }

    if (provider.filteredAppointments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing32),
        child: EmptyState(
          title: 'No Appointments',
          subtitle: 'Book your first appointment to get started',
          icon: Icons.calendar_today,
          onRetry: () => context.push('/appointments/book'),
          retryLabel: 'Book Now',
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: provider.filteredAppointments.length,
      itemBuilder: (context, index) {
        final appointment = provider.filteredAppointments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
          child: _buildAppointmentCard(context, appointment),
        );
      },
    );
  }

  Widget _buildAppointmentCard(BuildContext context, dynamic appointment) {
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
                      'Appointment #${appointment.appointmentId}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      appointment.warehouseName ?? 'Warehouse',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: appointment.status.toUpperCase(),
                status: appointment.status,
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
            label: 'Date & Time',
            value: '${appointment.scheduledDate} ${appointment.scheduledTime}',
          ),
          if (appointment.grainName != null) ...[
            const SizedBox(height: AppTheme.spacing8),
            InfoRow(
              label: 'Grain Type',
              value: appointment.grainName ?? 'N/A',
            ),
          ],
          if (appointment.quantityBags != null) ...[
            const SizedBox(height: AppTheme.spacing8),
            InfoRow(
              label: 'Quantity',
              value: '${appointment.quantityBags} bags',
            ),
          ],
          const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.push('/appointments/${appointment.appointmentId}');
              },
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }
}

