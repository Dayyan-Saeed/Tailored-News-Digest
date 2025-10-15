import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/logger.dart';

class ApiService {
  final String baseUrl = ApiConfig.baseUrl;
  
  // Add authorization token to headers
  Map<String, String> _getHeaders([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      logger.e('API Error: ${response.statusCode}', response.body);
      throw Exception('Failed to process request: ${response.statusCode}');
    }
  }

  // Authentication
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.login}'),
        headers: _getHeaders(),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      logger.e('Login error', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.register}'),
        headers: _getHeaders(),
        body: json.encode(userData),
      );
      return _handleResponse(response);
    } catch (e) {
      logger.e('Registration error', e);
      rethrow;
    }
  }

  // News and Recommendations
  Future<List<dynamic>> getRecommendations(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.recommend}'),
        headers: _getHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      logger.e('Get recommendations error', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSummary(String content, {String language = 'en'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.summary}'),
        headers: _getHeaders(),
        body: json.encode({
          'content': content,
          'language': language,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      logger.e('Get summary error', e);
      rethrow;
    }
  }

  // User Interactions
  Future<void> logReading(String articleId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.logReading}'),
        headers: _getHeaders(token),
        body: json.encode({
          'article_id': articleId,
        }),
      );
      _handleResponse(response);
    } catch (e) {
      logger.e('Log reading error', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.userProfile}'),
        headers: _getHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      logger.e('Get user profile error', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAnalytics(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.analytics}'),
        headers: _getHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      logger.e('Get analytics error', e);
      rethrow;
    }
  }

  // Bookmarks
  Future<void> toggleBookmark(String articleId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.bookmark}'),
        headers: _getHeaders(token),
        body: json.encode({
          'article_id': articleId,
        }),
      );
      _handleResponse(response);
    } catch (e) {
      logger.e('Toggle bookmark error', e);
      rethrow;
    }
  }

  // Premium Features
  Future<Map<String, dynamic>> upgradeToPremium(String token, String paymentInfo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.upgradeToPremium}'),
        headers: _getHeaders(token),
        body: json.encode({
          'payment_info': paymentInfo,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      logger.e('Upgrade to premium error', e);
      rethrow;
    }
  }
} 