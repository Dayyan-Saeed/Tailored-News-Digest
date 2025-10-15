import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';
import '../utils/theme_provider.dart';
import '../widgets/common/custom_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;

  // Settings
  bool _enableNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    try {
      setState(() => _isLoading = true);

      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        if (userData != null) {
          setState(() {
            _user = userData;

            // Load app preferences
            _enableNotifications =
                userData.preferences['enableNotifications'] ?? true;
          });
        }
      }
    } catch (e) {
      logger.e('Error loading user settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      setState(() => _isLoading = true);

      if (_user != null) {
        // Get theme settings from provider
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);

        // Update the user model with new settings
        final updatedUser = _user!.copyWith(
          accessibilitySettings: {
            'isDarkMode': themeProvider.isDarkMode,
            'fontSize': themeProvider.fontSize,
            'isTextToSpeechEnabled':
                _user!.accessibilitySettings['isTextToSpeechEnabled'] ?? false,
          },
          preferences: {
            'enableNotifications': _enableNotifications,
          },
        );

        await _authService.updateUserProfile(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully')),
          );
        }
      }
    } catch (e) {
      logger.e('Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance
            const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme throughout the app'),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                  ListTile(
                    title: const Text('Text Size'),
                    subtitle: Slider(
                      value: themeProvider.fontSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 12,
                      label: '${themeProvider.fontSize.toInt()}',
                      onChanged: (value) {
                        themeProvider.setFontSize(value);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Accessibility
            const Text(
              'Accessibility',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                title: const Text('Text-to-Speech'),
                subtitle: const Text('Read articles summaries aloud'),
                value: _user?.accessibilitySettings['isTextToSpeechEnabled'] ??
                    false,
                onChanged: (value) {
                  if (_user != null) {
                    final updatedSettings =
                        Map<String, dynamic>.from(_user!.accessibilitySettings);
                    updatedSettings['isTextToSpeechEnabled'] = value;

                    setState(() {
                      _user = _user!
                          .copyWith(accessibilitySettings: updatedSettings);
                    });
                  }
                },
              ),
            ),


            const SizedBox(height: 24),

            // Notifications
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text(
                    'Get alerts for breaking news and personalized recommendations'),
                value: _enableNotifications,
                onChanged: (value) {
                  setState(() => _enableNotifications = value);
                  _saveSettings();
                },
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            CustomButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
