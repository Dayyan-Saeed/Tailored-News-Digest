import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  
  // API Endpoints
  static const String login = '/api/login/';
  static const String register = '/api/register/';
  static const String summary = '/api/summary/';
  static const String recommend = '/api/recommend/';
  static const String comment = '/api/comment/';
  static const String readingLog = '/api/readinglog/';
  static const String analytics = '/api/analytics/';
  static const String sentiment = '/api/sentiment/';
  static const String bookmark = '/api/bookmark/';
  static const String unlockPremiumSummary = '/api/summary/unlock/';
  static const String logReading = '/api/reading/log/';
  static const String userProfile = '/api/user/profile/';
  static const String upgradeToPremium = '/api/user/upgrade/';
} 