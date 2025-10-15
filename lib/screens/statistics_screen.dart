import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/recommendation_service.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _authService = AuthService();
  final _recommendationService = RecommendationService();
  bool _isLoading = true;
  UserModel? _user;

  // Reading statistics
  int _totalArticlesRead = 0;
  int _articlesThisWeek = 0;
  Map<String, double> _emotionPreferences = {};
  Map<String, int> _categoryBreakdown = {};

  // Time ranges for the dropdown
  final List<String> _timeRanges = ['This Week', 'This Month', 'All Time'];
  String _selectedTimeRange = 'This Week';

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      setState(() => _isLoading = true);

      final user = _authService.currentUser;
      if (user != null) {
        // Load user data
        final userData = await _authService.getUserData(user.uid);

        if (userData != null) {
          // Get emotion preferences
          final emotionPrefs =
              await _recommendationService.getUserEmotionPreferences(user.uid);

          // Simulate fetching reading stats data (normally from Firestore)
          // In a real app, you would fetch this from your database
          final readingStats = await _fetchReadingStats(userData.id);

          setState(() {
            _user = userData;
            _emotionPreferences = emotionPrefs;
            _totalArticlesRead = readingStats['totalRead'] ?? 0;
            _articlesThisWeek = readingStats['thisWeek'] ?? 0;
            _categoryBreakdown =
                Map<String, int>.from(readingStats['categories'] ?? {});
          });
        }
      }
    } catch (e) {
      logger.e('Error loading user statistics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load statistics: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Simulate fetching reading stats (in a real app, this would be a Firestore query)
  Future<Map<String, dynamic>> _fetchReadingStats(String userId) async {
    // This is a placeholder. In a real app, you would retrieve this from Firestore
    // For demo purposes, we're returning mock data.
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay

    return {
      'totalRead': 32,
      'thisWeek': 8,
      'thisMonth': 22,
      'categories': {
        'Technology': 10,
        'Science': 7,
        'Health': 5,
        'Business': 4,
        'Entertainment': 3,
        'Sports': 2,
        'General': 1,
      }
    };
  }

  void _onTimeRangeChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedTimeRange = value;
        // In a real app, you would reload the stats for the selected time range
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Reading Stats'),
        actions: [
          DropdownButton<String>(
            underline: Container(),
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            dropdownColor: Theme.of(context).primaryColor,
            value: _selectedTimeRange,
            onChanged: _onTimeRangeChanged,
            items: _timeRanges.map((range) {
              return DropdownMenuItem<String>(
                value: range,
                child: Text(
                  range,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reading summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reading Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatTile(
                      icon: Icons.article,
                      title: 'Total Articles Read',
                      value: '$_totalArticlesRead',
                    ),
                    const Divider(),
                    _buildStatTile(
                      icon: Icons.calendar_today,
                      title: 'Articles Read This Week',
                      value: '$_articlesThisWeek',
                    ),
                    const Divider(),
                    _buildStatTile(
                      icon: Icons.emoji_events,
                      title: 'Total Points Earned',
                      value: '${_user?.points ?? 0}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Emotional Engagement
            if (_emotionPreferences.isNotEmpty) ...[
              const Text(
                'Emotional Engagement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildEmotionChart(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Category Breakdown
            if (_categoryBreakdown.isNotEmpty) ...[
              const Text(
                'Category Breakdown',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildCategoryBreakdown(),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Reading Streak
            const Text(
              'Reading Streak',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (index) {
                        // Mock data for the week
                        final isRead =
                            index < 5; // 5 out of 7 days have been read
                        return _buildDayIndicator(
                          day: _getDayName(index),
                          isRead: isRead,
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Current Streak: 5 days',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Longest Streak: 12 days',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionChart() {
    // Extract and sort emotions by value
    final emotions = _emotionPreferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Create a map of emotion to icon and color
    final emotionData = {
      'happy': {'icon': Icons.sentiment_satisfied, 'color': Colors.amber},
      'sad': {'icon': Icons.sentiment_dissatisfied, 'color': Colors.blue},
      'angry': {'icon': Icons.sentiment_very_dissatisfied, 'color': Colors.red},
      'surprised': {
        'icon': Icons.sentiment_satisfied_alt,
        'color': Colors.purple
      },
      'neutral': {'icon': Icons.sentiment_neutral, 'color': Colors.grey},
    };

    return Column(
      children: emotions.map((entry) {
        final emotion = entry.key;
        final percentage = (entry.value * 100).toInt();
        final data = emotionData[emotion] ??
            {'icon': Icons.emoji_emotions, 'color': Colors.grey};

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Icon(data['icon'] as IconData, color: data['color'] as Color),
              const SizedBox(width: 12),
              Text(
                '${emotion.substring(0, 1).toUpperCase()}${emotion.substring(1)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LinearProgressIndicator(
                  value: entry.value,
                  backgroundColor: (data['color'] as Color).withOpacity(0.1),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(data['color'] as Color),
                ),
              ),
              const SizedBox(width: 12),
              Text('$percentage%',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryBreakdown() {
    // Calculate total
    final totalArticles =
        _categoryBreakdown.values.fold<int>(0, (sum, count) => sum + count);

    // Extract and sort categories by count
    final categories = _categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: categories.map((entry) {
        final category = entry.key;
        final count = entry.value;
        final percentage = totalArticles > 0 ? (count / totalArticles) : 0.0;

        // Assign a color based on category
        final color = _getCategoryColor(category);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Icon(Icons.circle, color: color, size: 12),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(width: 12),
              Text('$count',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayIndicator({required String day, required bool isRead}) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isRead ? Theme.of(context).primaryColor : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: isRead ? Colors.white : Colors.grey[400],
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(day),
      ],
    );
  }

  String _getDayName(int index) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[index];
  }

  Color _getCategoryColor(String category) {
    final categoryColors = {
      'Technology': Colors.blue,
      'Science': Colors.purple,
      'Health': Colors.green,
      'Business': Colors.amber,
      'Entertainment': Colors.pink,
      'Sports': Colors.orange,
      'General': Colors.teal,
    };

    return categoryColors[category] ?? Colors.grey;
  }
}
