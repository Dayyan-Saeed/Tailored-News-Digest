import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/recommendation_service.dart';
import '../widgets/news/news_card.dart';
import '../utils/logger.dart';
import 'news_detail_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _authService = AuthService();
  final _recommendationService = RecommendationService();
  bool _isLoading = true;
  List<NewsModel> _recommendedNews = [];
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndRecommendations();
  }

  Future<void> _loadUserDataAndRecommendations() async {
    try {
      setState(() => _isLoading = true);

      // Step 1: Get current user
      final user = _authService.currentUser;
      if (user != null) {
        // Step 2: Load user data
        _user = await _authService.getUserData(user.uid);

        // Step 3: Get recommendations
        if (_user != null) {
          _recommendedNews = await _recommendationService.getRecommendedNews(
            userId: _user!.id,
          );
        }
      }
    } catch (e) {
      logger.e('Error loading recommendations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recommendations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    return _loadUserDataAndRecommendations();
  }

  void _handleNewsTap(NewsModel news) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(news: news),
      ),
    ).then((_) => _loadUserDataAndRecommendations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('For You'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recommendedNews.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recommendedNews.length,
                    itemBuilder: (context, index) {
                      final news = _recommendedNews[index];
                      final isLocked =
                          news.pointsRequired > (_user?.points ?? 0);
                      return NewsCard(
                        news: news,
                        onTap: () => _handleNewsTap(news),
                        isLocked: isLocked,
                        userPoints: _user?.points ?? 0,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.recommend,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Recommendations Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Interact with more articles to get personalized recommendations based on your emotions.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _handleRefresh,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
