import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/auth_provider.dart';
import 'providers/warehouse_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/delivery_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/grain_provider.dart';
import 'providers/zone_provider.dart';
import 'providers/timeslot_provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize API service
  final apiService = ApiService();
  
  // Initialize auth service
  final authService = AuthService(apiService, prefs);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProvider(
          create: (_) => WarehouseProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AppointmentProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => DeliveryProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => GrainProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ZoneProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => TimeSlotProvider(apiService),
        ),
      ],
      child: const MahsoulApp(),
    ),
  );
}

class MahsoulApp extends StatelessWidget {
  const MahsoulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mahsoul',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.createRouter(context),
    );
  }
}

