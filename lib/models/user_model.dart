import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final int points;
  final List<String> interests;
  final List<String> savedArticles;
  final Map<String, dynamic> accessibilitySettings;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.points = 0,
    this.interests = const [],
    this.savedArticles = const [],
    this.accessibilitySettings = const {},
    this.preferences = const {},
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      points: data['points'] ?? 0,
      interests: List<String>.from(data['interests'] ?? []),
      savedArticles: List<String>.from(data['savedArticles'] ?? []),
      accessibilitySettings:
          Map<String, dynamic>.from(data['accessibilitySettings'] ?? {}),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'points': points,
      'interests': interests,
      'savedArticles': savedArticles,
      'accessibilitySettings': accessibilitySettings,
      'preferences': preferences,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    int? points,
    List<String>? interests,
    List<String>? savedArticles,
    Map<String, dynamic>? accessibilitySettings,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      points: points ?? this.points,
      interests: interests ?? this.interests,
      savedArticles: savedArticles ?? this.savedArticles,
      accessibilitySettings:
          accessibilitySettings ?? this.accessibilitySettings,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
