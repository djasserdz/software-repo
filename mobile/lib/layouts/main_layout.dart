import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainLayout({
    Key? key,
    required this.child,
    required this.currentRoute,
  }) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _getIndexFromRoute(widget.currentRoute);
  }

  @override
  void didUpdateWidget(MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _selectedIndex = _getIndexFromRoute(widget.currentRoute);
    }
  }

  int _getIndexFromRoute(String route) {
    if (route.startsWith('/warehouses')) return 0;
    if (route.startsWith('/appointments')) return 1;
    if (route.startsWith('/deliveries')) return 2;
    if (route.startsWith('/profile')) return 3;
    return 0;
  }

  void _onNavBarTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        context.go('/warehouses');
        break;
      case 1:
        context.go('/appointments');
        break;
      case 2:
        context.go('/deliveries');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hide bottom nav on auth pages and admin pages
    final hideBottomNav = widget.currentRoute.startsWith('/login') ||
        widget.currentRoute.startsWith('/register') ||
        widget.currentRoute.startsWith('/admin') ||
        widget.currentRoute.startsWith('/warehouse-admin') ||
        widget.currentRoute.startsWith('/dashboard');

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: hideBottomNav
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onNavBarTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppTheme.primaryColor,
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.warehouse_outlined),
                  activeIcon: Icon(Icons.warehouse),
                  label: 'Warehouses',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  activeIcon: Icon(Icons.calendar_today),
                  label: 'Appointments',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_shipping_outlined),
                  activeIcon: Icon(Icons.local_shipping),
                  label: 'Deliveries',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}
