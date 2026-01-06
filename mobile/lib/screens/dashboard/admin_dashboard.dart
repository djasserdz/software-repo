import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.fetchStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Statistics Section
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Consumer<AdminProvider>(
                builder: (context, adminProvider, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Overview',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: AppTheme.spacing12,
                        mainAxisSpacing: AppTheme.spacing12,
                        childAspectRatio: 1.1,
                        children: [
                          _buildStatCard(
                            context,
                            'Total Users',
                            adminProvider.totalUsers.toString(),
                            Icons.people,
                            AppTheme.primaryColor,
                          ),
                          _buildStatCard(
                            context,
                            'Warehouses',
                            adminProvider.totalWarehouses.toString(),
                            Icons.warehouse,
                            AppTheme.successColor,
                          ),
                          _buildStatCard(
                            context,
                            'Appointments',
                            adminProvider.totalAppointments.toString(),
                            Icons.calendar_today,
                            AppTheme.warningColor,
                          ),
                          _buildStatCard(
                            context,
                            'Deliveries',
                            adminProvider.totalDeliveries.toString(),
                            Icons.local_shipping,
                            AppTheme.infoColor,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            // Quick Actions Section
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppTheme.spacing12,
                    mainAxisSpacing: AppTheme.spacing12,
                    childAspectRatio: 1.2,
                    children: [
                      _buildActionCard(
                        context,
                        'Manage Users',
                        Icons.people_outline,
                        AppTheme.primaryColor,
                        () => context.push('/admin/users'),
                      ),
                      _buildActionCard(
                        context,
                        'Warehouses',
                        Icons.warehouse,
                        AppTheme.successColor,
                        () => context.push('/admin/warehouses'),
                      ),
                      _buildActionCard(
                        context,
                        'Grains',
                        Icons.grass_outlined,
                        AppTheme.warningColor,
                        () => context.push('/admin/grains'),
                      ),
                      _buildActionCard(
                        context,
                        'Appointments',
                        Icons.calendar_today_outlined,
                        AppTheme.primaryDark,
                        () => context.push('/admin/appointments'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Recent Activity Section
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Tools',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  CustomCard(
                    child: Column(
                      children: [
                        ListItemTile(
                          title: 'System Logs',
                          subtitle: 'View system activity and logs',
                          leadingIcon: Icons.description_outlined,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('System logs coming soon'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 16),
                        ListItemTile(
                          title: 'Backup & Export',
                          subtitle: 'Backup data and export reports',
                          leadingIcon: Icons.cloud_download_outlined,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Backup & Export coming soon'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 16),
                        ListItemTile(
                          title: 'System Settings',
                          subtitle: 'Configure system preferences',
                          leadingIcon: Icons.settings_outlined,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settings coming soon'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(
              'Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

