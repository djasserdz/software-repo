import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/timeslot_provider.dart';
import '../../providers/zone_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class WarehouseAdminTimeslotsScreen extends StatefulWidget {
  const WarehouseAdminTimeslotsScreen({super.key});

  @override
  State<WarehouseAdminTimeslotsScreen> createState() =>
      _WarehouseAdminTimeslotsScreenState();
}

class _WarehouseAdminTimeslotsScreenState
    extends State<WarehouseAdminTimeslotsScreen> {
  int? _selectedZoneId;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  String? _selectedStatus;
  bool _showCreateDialog = false;
  bool _showEditDialog = false;
  int? _editingTimeSlotId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final zoneProvider = Provider.of<ZoneProvider>(context, listen: false);
      zoneProvider.fetchZones();
    });
  }

  void _openCreateDialog() {
    setState(() {
      _showCreateDialog = true;
      _selectedStartDate = null;
      _selectedEndDate = null;
      _selectedStartTime = null;
      _selectedEndTime = null;
      _selectedStatus = 'active';
    });
  }

  void _openEditDialog(timeSlot) {
    setState(() {
      _showEditDialog = true;
      _editingTimeSlotId = timeSlot.timeId;
      _selectedZoneId = timeSlot.zoneId;
      _selectedStartDate = timeSlot.startAt;
      _selectedEndDate = timeSlot.endAt;
      _selectedStartTime = TimeOfDay.fromDateTime(timeSlot.startAt);
      _selectedEndTime = TimeOfDay.fromDateTime(timeSlot.endAt);
      _selectedStatus = timeSlot.status;
    });
  }

  void _closeDialogs() {
    setState(() {
      _showCreateDialog = false;
      _showEditDialog = false;
      _editingTimeSlotId = null;
    });
  }

  Future<void> _createTimeSlot() async {
    if (_selectedZoneId == null ||
        _selectedStartDate == null ||
        _selectedEndDate == null ||
        _selectedStartTime == null ||
        _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final startDateTime = DateTime(
      _selectedStartDate!.year,
      _selectedStartDate!.month,
      _selectedStartDate!.day,
      _selectedStartTime!.hour,
      _selectedStartTime!.minute,
    );

    final endDateTime = DateTime(
      _selectedEndDate!.year,
      _selectedEndDate!.month,
      _selectedEndDate!.day,
      _selectedEndTime!.hour,
      _selectedEndTime!.minute,
    );

    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final provider = Provider.of<TimeSlotProvider>(context, listen: false);
    final success = await provider.createTimeSlot(
      zoneId: _selectedZoneId!,
      startAt: startDateTime,
      endAt: endDateTime,
      status: _selectedStatus ?? 'active',
    );

    if (success) {
      _closeDialogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time slot created successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to create time slot')),
      );
    }
  }

  Future<void> _updateTimeSlot() async {
    if (_editingTimeSlotId == null ||
        _selectedStartDate == null ||
        _selectedEndDate == null ||
        _selectedStartTime == null ||
        _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final startDateTime = DateTime(
      _selectedStartDate!.year,
      _selectedStartDate!.month,
      _selectedStartDate!.day,
      _selectedStartTime!.hour,
      _selectedStartTime!.minute,
    );

    final endDateTime = DateTime(
      _selectedEndDate!.year,
      _selectedEndDate!.month,
      _selectedEndDate!.day,
      _selectedEndTime!.hour,
      _selectedEndTime!.minute,
    );

    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final provider = Provider.of<TimeSlotProvider>(context, listen: false);
    final success = await provider.updateTimeSlot(
      timeId: _editingTimeSlotId!,
      zoneId: _selectedZoneId,
      startAt: startDateTime,
      endAt: endDateTime,
      status: _selectedStatus,
    );

    if (success) {
      _closeDialogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time slot updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to update time slot')),
      );
    }
  }

  Future<void> _deleteTimeSlot(int timeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Slot'),
        content: const Text('Are you sure you want to delete this time slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<TimeSlotProvider>(context, listen: false);
      final success = await provider.deleteTimeSlot(timeId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Time slot deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to delete time slot')),
        );
      }
    }
  }

  Future<void> _generateNextDay() async {
    final provider = Provider.of<TimeSlotProvider>(context, listen: false);
    final result = await provider.generateNextDay();
    
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Time slots generated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to generate time slots')),
      );
    }
  }

  Future<void> _generateWeek() async {
    final provider = Provider.of<TimeSlotProvider>(context, listen: false);
    final result = await provider.generateWeek();
    
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Time slots generated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to generate time slots')),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(
        title: const Text('Time Slots'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<TimeSlotProvider>(context, listen: false);
              if (_selectedZoneId != null) {
                provider.fetchTimeSlots(_selectedZoneId!);
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<TimeSlotProvider>(
        builder: (context, timeSlotProvider, _) {
          return Consumer<ZoneProvider>(
            builder: (context, zoneProvider, _) {
          final zones = zoneProvider.zones;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Column(
                  children: [
                    DropdownButtonFormField<int?>(
                      value: _selectedZoneId,
                      decoration: const InputDecoration(
                        labelText: 'Select Zone *',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Select a zone')),
                        ...zones.map((z) => DropdownMenuItem<int?>(
                          value: z.zoneId,
                          child: Text('${z.name} (Zone #${z.zoneId})'),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedZoneId = value);
                        if (value != null) {
                          timeSlotProvider.fetchTimeSlots(value);
                        }
                      },
                    ),
                    if (_selectedZoneId != null) ...[
                      const SizedBox(height: AppTheme.spacing12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.today, size: 18),
                              label: const Text('Generate Next Day'),
                              onPressed: timeSlotProvider.isLoading ? null : _generateNextDay,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.calendar_view_week, size: 18),
                              label: const Text('Generate Week'),
                              onPressed: timeSlotProvider.isLoading ? null : _generateWeek,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    _selectedZoneId == null
                        ? const Center(
                            child: Text('Please select a zone to view time slots'),
                          )
                        : timeSlotProvider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : timeSlotProvider.timeSlots.isEmpty
                                ? const EmptyState(
                                    icon: Icons.access_time_outlined,
                                    title: 'No Time Slots',
                                    subtitle: 'Create time slots or generate from templates',
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(AppTheme.spacing12),
                                    itemCount: timeSlotProvider.timeSlots.length,
                                    itemBuilder: (context, index) {
                                      final slot = timeSlotProvider.timeSlots[index];

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
                                        child: CustomCard(
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
                                                          _formatDateTime(slot.startAt),
                                                          style: Theme.of(context).textTheme.titleMedium,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          'To: ${_formatDateTime(slot.endAt)}',
                                                          style: Theme.of(context).textTheme.bodySmall,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  StatusBadge(
                                                    label: slot.status.toUpperCase(),
                                                    status: slot.status,
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
                                                    onPressed: () => _openEditDialog(slot),
                                                  ),
                                                  TextButton.icon(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                    onPressed: () => _deleteTimeSlot(slot.timeId),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                  ],
                ),
              ),
            ],
          );
            },
          );
        },
      ),
      floatingActionButton: _selectedZoneId != null
          ? FloatingActionButton(
              onPressed: _openCreateDialog,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
        ),
        // Create/Edit Dialog
        if (_showCreateDialog || _showEditDialog)
          _buildTimeSlotDialog(
            title: _showCreateDialog ? 'Create Time Slot' : 'Edit Time Slot',
            onSave: _showCreateDialog ? _createTimeSlot : _updateTimeSlot,
          ),
      ],
    );
  }

  Widget _buildTimeSlotDialog({
    required String title,
    required VoidCallback onSave,
  }) {
    return Consumer<ZoneProvider>(
      builder: (context, zoneProvider, _) {
        final zones = zoneProvider.zones;

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
                DropdownButtonFormField<int>(
                  value: _selectedZoneId,
                  decoration: const InputDecoration(
                    labelText: 'Zone *',
                    border: OutlineInputBorder(),
                  ),
                  items: zones.map((z) => DropdownMenuItem<int>(
                    value: z.zoneId,
                    child: Text('${z.name} (Zone #${z.zoneId})'),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedZoneId = value);
                  },
                ),
                const SizedBox(height: AppTheme.spacing12),
                ListTile(
                  title: const Text('Start Date *'),
                  subtitle: Text(
                    _selectedStartDate == null
                        ? 'Select start date'
                        : DateFormat('yyyy-MM-dd').format(_selectedStartDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _selectedStartDate = date);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacing8),
                ListTile(
                  title: const Text('Start Time *'),
                  subtitle: Text(
                    _selectedStartTime == null
                        ? 'Select start time'
                        : _selectedStartTime!.format(context),
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() => _selectedStartTime = time);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacing12),
                ListTile(
                  title: const Text('End Date *'),
                  subtitle: Text(
                    _selectedEndDate == null
                        ? 'Select end date'
                        : DateFormat('yyyy-MM-dd').format(_selectedEndDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedStartDate ?? DateTime.now(),
                      firstDate: _selectedStartDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _selectedEndDate = date);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacing8),
                ListTile(
                  title: const Text('End Time *'),
                  subtitle: Text(
                    _selectedEndTime == null
                        ? 'Select end time'
                        : _selectedEndTime!.format(context),
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() => _selectedEndTime = time);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacing12),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'not_active', child: Text('Not Active')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
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
