import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService apiService;
  final SharedPreferences prefs;

  AuthService(this.apiService, this.prefs);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔵 [AUTH] Login attempt for: $email');
      final response = await apiService.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      print('🟢 [AUTH] Response status: ${response.statusCode}');
      print('🟢 [AUTH] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final token = responseData['token'] as String?;
        final userJson = responseData['user'];

        print('🟡 [AUTH] Token: ${token?.substring(0, 20)}...');
        print('🟡 [AUTH] User JSON: $userJson');

        if (token == null) {
          return {
            'success': false,
            'message': 'No token received from server',
          };
        }

        // Store token and user
        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(userJson));

        final user = User.fromJson(userJson);
        print('✅ [AUTH] Login successful for user: ${user.name}');

        return {
          'success': true,
          'user': user,
          'token': token,
        };
      } else {
        final responseData = response.data as Map<String, dynamic>?;
        final message = responseData?['detail'] ?? 'Login failed';
        print('❌ [AUTH] Login failed: $message');
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      print('❌ [AUTH] Exception: $e');
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String role,
  }) async {
    try {
      // Convert role to lowercase (backend expects lowercase)
      final normalizedRole = role.toLowerCase();
      
      print('🔵 [AUTH] Register attempt: email=$email, role=$normalizedRole');

      final response = await apiService.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone ?? '',
          'role': normalizedRole,
        },
      );

      print('🟢 [AUTH] Register response status: ${response.statusCode}');
      print('🟢 [AUTH] Register response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final token = responseData['token'] as String?;
        final userJson = responseData['user'];

        print('🟡 [AUTH] Token received: ${token?.substring(0, 20)}...');
        print('🟡 [AUTH] User JSON: $userJson');

        if (token == null) {
          return {
            'success': false,
            'message': 'No token received from server',
          };
        }

        // Store token and user
        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(userJson));

        final user = User.fromJson(userJson);
        print('✅ [AUTH] Registration successful for: ${user.email}');

        return {
          'success': true,
          'user': user,
          'token': token,
        };
      } else {
        final responseData = response.data as Map<String, dynamic>?;
        final message = responseData?['detail'] ?? 'Registration failed';
        print('❌ [AUTH] Registration failed: $message');
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      print('❌ [AUTH] Register exception: $e');
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  Future<void> logout() async {
    await prefs.remove('token');
    await prefs.remove('user');
  }

  User? getCurrentUser() {
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  String? getToken() {
    return prefs.getString('token');
  }

  bool get isAuthenticated => getToken() != null && getCurrentUser() != null;
}

