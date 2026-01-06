import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Callback for handling unauthorized errors
typedef OnUnauthorized = Future<void> Function();

class ApiService {
  late Dio _dio;
  final String baseUrl;
  OnUnauthorized? onUnauthorized;
  
  // Get base URL from environment or use default
  static String getBaseUrl() {
    final appEnv = dotenv.env['APP_ENV'] ?? 'dev';
    if (appEnv == 'prod') {
      return dotenv.env['BACKEND_API_PROD'] ?? 'http://api.mahsoul.com/api';
    } else {
      return dotenv.env['BACKEND_API_DEV'] ?? 'http://10.0.2.2:8000/api';
    }
  }

  ApiService({String? baseUrl, this.onUnauthorized})
      : baseUrl = baseUrl ?? getBaseUrl() {
    _initDio();
  }

  void setOnUnauthorizedCallback(OnUnauthorized callback) {
    onUnauthorized = callback;
  }

  void _initDio() {
    _dio = Dio()
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(seconds: 30)
      ..options.receiveTimeout = const Duration(seconds: 30)
      ..options.headers['Content-Type'] = 'application/json';
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('🔐 [API] Authorization header added');
        } else {
          print('⚠️ [API] No token found for request: ${options.path}');
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        print('❌ [API] Error: ${error.response?.statusCode} - ${error.message}');
        
        if (error.response?.statusCode == 401) {
          print('🔴 [API] Unauthorized (401) - Clearing authentication');
          // Handle unauthorized - clear token and redirect to login
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.remove('user');
          
          // Call the unauthorized callback if set
          if (onUnauthorized != null) {
            await onUnauthorized!();
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      print('📤 [API] GET $path');
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      print('❌ [API] GET Error: $e');
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      print('📤 [API] POST $path');
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      print('❌ [API] POST Error: $e');
      rethrow;
    }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      print('📤 [API] PATCH $path');
      return await _dio.patch(path, data: data);
    } catch (e) {
      print('❌ [API] PATCH Error: $e');
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      print('📤 [API] PUT $path');
      return await _dio.put(path, data: data);
    } catch (e) {
      print('❌ [API] PUT Error: $e');
      rethrow;
    }
  }

  Future<Response> delete(String path) async {
    try {
      print('📤 [API] DELETE $path');
      return await _dio.delete(path);
    } catch (e) {
      print('❌ [API] DELETE Error: $e');
      rethrow;
    }
  }
}

