import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';
import '../utils/logger.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get recommended news based on user's emotional patterns
  Future<List<NewsModel>> getRecommendedNews({
    required String userId,
    int limit = 10,
  }) async {
    try {
      logger.i('Getting recommended news for user: $userId');

      // Step 1: Get user's emotional preferences
      final userEmotionPreferences = await getUserEmotionPreferences(userId);
      logger.d('User emotion preferences: $userEmotionPreferences');

      // If no preferences yet, return trending news
      if (userEmotionPreferences.isEmpty) {
        logger.i('No emotion preferences found, returning trending news');
        return _getTrendingNews(limit: limit);
      }

      // Step 2: Sort emotions by preference weight
      final sortedEmotions = userEmotionPreferences.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Step 3: Get the top 2 preferred emotions
      final topEmotions = sortedEmotions.take(2).map((e) => e.key).toList();
      logger.d('Top emotions: $topEmotions');

      // Step 4: Query articles with high counts of these emotions
      return _getNewsWithEmotions(topEmotions, limit: limit);
    } catch (e) {
      logger.e('Error getting recommended news: $e');
      // Fall back to trending news
      return _getTrendingNews(limit: limit);
    }
  }

  /// Calculate user's emotional preferences based on their interaction history
  Future<Map<String, double>> getUserEmotionPreferences(String userId) async {
    try {
      // Get user's recent emotion interactions from saved or read articles
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return {};
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final savedArticles = List<String>.from(userData['savedArticles'] ?? []);

      // Initialize emotion counter
      final emotionCounts = <String, int>{
        'happy': 0,
        'sad': 0,
        'angry': 0,
        'surprised': 0,
        'neutral': 0,
      };

      // Get all articles the user has saved
      if (savedArticles.isNotEmpty) {
        final articleDocs = await Future.wait(savedArticles
            .map((id) => _firestore.collection('news').doc(id).get()));

        // Count emotions in these articles
        for (final doc in articleDocs) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final emotions = Map<String, int>.from(data['emotions'] ?? {});

            // Add to our counts
            emotions.forEach((emotion, countValue) {
              emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
            });
          }
        }
      }

      // Convert counts to preference weights (0.0 to 1.0)
      final totalCount = emotionCounts.values
          .fold<int>(0, (total, countValue) => total + countValue);
      final preferences = <String, double>{};

      if (totalCount > 0) {
        emotionCounts.forEach((emotion, countValue) {
          preferences[emotion] = countValue / totalCount;
        });
      }

      return preferences;
    } catch (e) {
      logger.e('Error calculating user emotion preferences: $e');
      return {};
    }
  }

  /// Get news with specified emotions
  Future<List<NewsModel>> _getNewsWithEmotions(
    List<String> emotions, {
    int limit = 10,
  }) async {
    try {
      // For each emotion, find articles with highest counts
      final emotionQueries = await Future.wait(emotions.map((emotion) =>
          _firestore
              .collection('news')
              .orderBy('publishedAt', descending: true)
              .limit(limit)
              .get()
              .then((snapshot) => snapshot.docs
                  .map((doc) => NewsModel.fromFirestore(doc))
                  .where((news) =>
                      news.emotions.containsKey(emotion) &&
                      (news.emotions[emotion] ?? 0) > 0)
                  .toList())));

      // Combine results from different emotions
      final result = <NewsModel>[];
      for (final articles in emotionQueries) {
        result.addAll(articles);
      }

      // Remove duplicates
      final uniqueResult = <NewsModel>[];
      final uniqueIds = <String>{};

      for (final article in result) {
        if (!uniqueIds.contains(article.id)) {
          uniqueResult.add(article);
          uniqueIds.add(article.id);
        }
      }

      // Limit results
      return uniqueResult.take(limit).toList();
    } catch (e) {
      logger.e('Error getting news with emotions: $e');
      return [];
    }
  }

  /// Get trending news (most emotional reactions)
  Future<List<NewsModel>> _getTrendingNews({int limit = 10}) async {
    try {
      logger.i('Getting trending news');

      final snapshot = await _firestore
          .collection('news')
          .orderBy('publishedAt', descending: true)
          .limit(limit *
              2) // Get more than needed to ensure we have articles with emotions
          .get();

      // Try to find articles with emotions
      final articlesWithEmotions = snapshot.docs
          .map((doc) => NewsModel.fromFirestore(doc))
          .where((news) => news.emotions.isNotEmpty)
          .take(limit)
          .toList();

      // If we have enough articles with emotions, return them
      if (articlesWithEmotions.length >= limit ~/ 2) {
        return articlesWithEmotions;
      }

      // Otherwise return most recent articles
      return snapshot.docs
          .map((doc) => NewsModel.fromFirestore(doc))
          .take(limit)
          .toList();
    } catch (e) {
      logger.e('Error getting trending news: $e');
      return [];
    }
  }
}
