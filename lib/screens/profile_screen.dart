import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/recommendation_service.dart';
import '../models/user_model.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_text_field.dart';
import '../utils/logger.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  final _recommendationService = RecommendationService();
  bool _isLoading = false;
  UserModel? _user;
  List<String> _selectedInterests = [];
  Map<String, double> _emotionPreferences = {};

  final List<String> _availableInterests = [
    'Business',
    'Entertainment',
    'General',
    'Health',
    'Science',
    'Sports',
    'Technology',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        if (userData != null) {
          // Get emotion preferences
          final emotionPrefs =
              await _recommendationService.getUserEmotionPreferences(user.uid);

          setState(() {
            _user = userData;
            _nameController.text = userData.name;
            _selectedInterests = List.from(userData.interests);
            _emotionPreferences = emotionPrefs;
          });
        }
      }
    }     catch (e) {
      logger.e('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_user != null) {
       final updatedUser = _user!.copyWith(
          name: _nameController.text.trim(),
          interests: _selectedInterests,
        );

        await _authService.updateUserProfile(updatedUser);
        setState(() => _user = updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      logger.e('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: Text('User data not available'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _user!.email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber[800],
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_user!.points} Points',
                            style: TextStyle(
                              color: Colors.amber[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Name Field
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Emotional Preferences
              if (_emotionPreferences.isNotEmpty) ...[
                const Text(
                  'Your Emotional Preferences',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Based on articles you interact with, we\'ve learned what emotions engage you most.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEmotionPreferencesChart(),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/statistics');
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Detailed Statistics'),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Interests
              const Text(
                'Interests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableInterests.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedInterests.add(interest);
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Points Bar/Status (Placeholder)
              const Text(
                'Points & Rewards',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const ListTile(
                title: Text('Points Balance: [User Points]'),
                subtitle: Text('Your current points and status.'),
              ),
              const SizedBox(height: 16),

              // Redeem Points (Placeholder)
              ElevatedButton(
                onPressed: () {
                  // Implement redeem points functionality in backend
                },
                child: const Text('Redeem Points'),
              ),
              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                onPressed: _isLoading ? null : _handleSaveProfile,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionPreferencesChart() {
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
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(data['icon'] as IconData, color: data['color'] as Color),
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
              Text('$percentage%'),
            ],
          ),
        );
      }).toList(),
    );
  }
}
