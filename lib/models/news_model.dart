import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final String url;
  final String imageUrl;
  final String source;
  final DateTime publishedAt;
  final String language;
  Map<String, int> emotions;
  final List<String> categories;
  final int pointsRequired;
  final String summary;
  final Map<String, dynamic> metadata;

  NewsModel({
    required String id,
    required this.title,
    required this.description,
    required this.content,
    required this.url,
    required this.imageUrl,
    required this.source,
    required this.publishedAt,
    required this.language,
    Map<String, int>? emotions,
    this.categories = const [],
    this.pointsRequired = 0,
    this.summary = '',
    this.metadata = const {},
  })  : id = _sanitizeId(id),
        emotions = emotions ?? {};

  // Method to sanitize the ID for Firestore
  static String _sanitizeId(String id) {
    return id.replaceAll('//', '_').replaceAll('/', '_');
  }

  // Get a Firestore-safe ID
  String get firestoreId => _sanitizeId(id);

  factory NewsModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return NewsModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      url: data['url'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      source: data['source'] ?? '',
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
      language: data['language'] ?? 'en',
      emotions: Map<String, int>.from(data['emotions'] ?? {}),
      categories: List<String>.from(data['categories'] ?? []),
      pointsRequired: data['pointsRequired'] ?? 0,
      summary: data['summary'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'url': url,
      'imageUrl': imageUrl,
      'source': source,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'language': language,
      'emotions': emotions,
      'categories': categories,
      'pointsRequired': pointsRequired,
      'summary': summary,
      'metadata': metadata,
    };
  }

  NewsModel copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? url,
    String? imageUrl,
    String? source,
    DateTime? publishedAt,
    String? language,
    Map<String, int>? emotions,
    List<String>? categories,
    int? pointsRequired,
    String? summary,
    Map<String, dynamic>? metadata,
  }) {
    return NewsModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source ?? this.source,
      publishedAt: publishedAt ?? this.publishedAt,
      language: language ?? this.language,
      emotions: emotions ?? this.emotions,
      categories: categories ?? this.categories,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      summary: summary ?? this.summary,
      metadata: metadata ?? this.metadata,
    );
  }
}
