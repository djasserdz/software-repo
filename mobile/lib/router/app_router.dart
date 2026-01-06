import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/farmer_dashboard.dart';
import '../screens/dashboard/admin_dashboard.dart';
import '../screens/dashboard/warehouse_admin_dashboard.dart';
import '../screens/warehouses/warehouses_screen.dart';
import '../screens/warehouses/warehouse_detail_screen.dart';
import '../screens/warehouses/warehouse_map_screen.dart';
import '../screens/appointments/appointments_screen.dart';
import '../screens/appointments/book_appointment_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/deliveries/deliveries_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_warehouses_screen.dart';
import '../screens/admin/admin_grains_screen.dart';
import '../screens/admin/admin_appointments_screen.dart';
import '../screens/warehouse_admin/warehouse_admin_warehouses_screen.dart';
import '../screens/warehouse_admin/warehouse_admin_zones_screen.dart';
import '../screens/warehouse_admin/warehouse_admin_timeslots_screen.dart';
import '../screens/warehouse_admin/warehouse_admin_appointments_screen.dart';
import '../screens/warehouse_admin/warehouse_admin_deliveries_screen.dart';
import '../layouts/main_layout.dart';

class _AuthNotifier extends ChangeNotifier {
  final AuthProvider authProvider;

  _AuthNotifier(this.authProvider) {
    authProvider.addListener(_notifyListeners);
  }

  void _notifyListeners() {
    notifyListeners();
  }

  @override
  void dispose() {
    authProvider.removeListener(_notifyListeners);
    super.dispose();
  }
}

class AppRouter {
  static GoRouter createRouter(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authNotifier = _AuthNotifier(authProvider);

    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authNotifier,
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoginRoute = state.matchedLocation == '/login' || 
                            state.matchedLocation == '/register';

        if (!isAuthenticated && !isLoginRoute) {
          return '/login';
        }

        if (isAuthenticated && isLoginRoute) {
          // Redirect to appropriate dashboard based on role
          if (authProvider.isAdmin) {
            return '/admin';
          } else if (authProvider.isWarehouseAdmin) {
            return '/warehouse-admin';
          } else {
            return '/warehouses';
          }
        }

        return null;
      },
    routes: [
      // Auth Routes (No Bottom Nav)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Admin Routes (No Bottom Nav)
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/warehouses',
        builder: (context, state) => const AdminWarehousesScreen(),
      ),
      GoRoute(
        path: '/admin/grains',
        builder: (context, state) => const AdminGrainsScreen(),
      ),
      GoRoute(
        path: '/admin/appointments',
        builder: (context, state) => const AdminAppointmentsScreen(),
      ),

      // Warehouse Admin Routes (No Bottom Nav)
      GoRoute(
        path: '/warehouse-admin',
        builder: (context, state) => const WarehouseAdminDashboard(),
      ),
      GoRoute(
        path: '/warehouse-admin/warehouses',
        builder: (context, state) => const WarehouseAdminWarehousesScreen(),
      ),
      GoRoute(
        path: '/warehouse-admin/zones',
        builder: (context, state) => const WarehouseAdminZonesScreen(),
      ),
      GoRoute(
        path: '/warehouse-admin/timeslots',
        builder: (context, state) => const WarehouseAdminTimeslotsScreen(),
      ),
      GoRoute(
        path: '/warehouse-admin/appointments',
        builder: (context, state) => const WarehouseAdminAppointmentsScreen(),
      ),
      GoRoute(
        path: '/warehouse-admin/deliveries',
        builder: (context, state) => const WarehouseAdminDeliveriesScreen(),
      ),

      // Farmer Dashboard (No Bottom Nav)
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const FarmerDashboard(),
      ),

      // Main App Routes (With Bottom Nav via ShellRoute)
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(
            currentRoute: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/warehouses',
            builder: (context, state) => const WarehousesScreen(),
            routes: [
              GoRoute(
                path: 'map',
                builder: (context, state) => const WarehouseMapScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return WarehouseDetailScreen(warehouseId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/appointments',
            builder: (context, state) => const AppointmentsScreen(),
            routes: [
              GoRoute(
                path: 'book',
                builder: (context, state) => const BookAppointmentScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/deliveries',
            builder: (context, state) => const DeliveriesScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    );
  }
}
