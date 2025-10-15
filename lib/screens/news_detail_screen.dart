// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
// ignore: unused_import
import '../screens/web_view_screen.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsModel news;

  const NewsDetailScreen({
    super.key,
    required this.news,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen>
    with SingleTickerProviderStateMixin {
  final _newsService = NewsService();
  final _authService = AuthService();
  bool _isSaved = false;
  String? _selectedEmotion;
  late AnimationController _emotionController;

  // Common emotions for news reactions
  final List<Map<String, dynamic>> _emotions = [
    {'name': 'Happy', 'icon': Icons.sentiment_very_satisfied},
    {'name': 'Sad', 'icon': Icons.sentiment_dissatisfied},
    {'name': 'Angry', 'icon': Icons.sentiment_very_dissatisfied},
    {'name': 'Surprised', 'icon': Icons.emoji_emotions},
    {'name': 'Informed', 'icon': Icons.psychology},
    {'name': 'Confused', 'icon': Icons.question_mark},
    {'name': 'Inspired', 'icon': Icons.emoji_objects}
  ];

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _emotionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _emotionController.dispose();
    super.dispose();
  }

  Future<void> _checkIfSaved() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        setState(() {
          _isSaved = userData!.savedArticles.contains(widget.news.firestoreId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check saved status: $e')),
        );
      }
    }
  }

  Future<void> _handleSaveArticle() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        final updatedArticles =
            List<String>.from(userData?.savedArticles ?? []);

        if (_isSaved) {
          updatedArticles.remove(widget.news.firestoreId);
        } else {
          updatedArticles.add(widget.news.firestoreId);
        }
        if (userData != null) {
          await _authService.updateUserProfile(
            userData.copyWith(savedArticles: updatedArticles),
          );
        }

        setState(() {
          _isSaved = !_isSaved;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save/unsave article: $e')),
        );
      }
    }
  }

  Future<void> _handleEmotionSelected(String emotion) async {
    try {
      // Create a copy of the current emotions and update it
      final updatedEmotions = Map<String, int>.from(widget.news.emotions);
      updatedEmotions[emotion] = (updatedEmotions[emotion] ?? 0) + 1;

      // First check if the article exists in Firestore
      logger.i('Checking if article exists: ${widget.news.firestoreId}');
      final existingArticle =
          await _newsService.getNewsById(widget.news.firestoreId);

      if (existingArticle == null) {
        logger.i('Article not found in Firestore. Saving it first...');
        // Create a copy with updated emotions
        final newsToSave = widget.news.copyWith(emotions: updatedEmotions);
        await _newsService.saveNews(newsToSave);
      } else {
        // Just update emotions on existing article
        logger.i('Updating emotions for existing article');
        await _newsService.updateNewsEmotions(
            widget.news.firestoreId, updatedEmotions);
      }

      // Update the UI
      if (mounted) {
        setState(() {
          // Update the emotions in our local model
          widget.news.emotions = updatedEmotions;
        });
      }
    } catch (e) {
      logger.e('Error updating emotion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update emotion: $e')),
        );
      }
    }
  }

  void _selectEmotion(String emotion) {
    setState(() {
      _selectedEmotion = emotion;
    });
    _handleEmotionSelected(emotion);
    _emotionController.reset();
    _emotionController.forward();
  }

  Future<void> _handleOpenArticle() async {
    try {
      // Check if this is mock content
      bool isMockData = widget.news.metadata['isMockData'] == true;
      if (isMockData) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'This is sample content. The full article is not available.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Check for valid URL
      if (widget.news.url.isEmpty) {
        throw 'Article URL is not available';
      }

      // Open directly in external browser - bypassing WebView
      await _openInExternalBrowser();
    } catch (e) {
      logger.e('Error opening article: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open article: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openInExternalBrowser() async {
    final url = Uri.parse(widget.news.url);
    if (await canLaunchUrl(url)) {
      logger.i('Opening article URL in external browser: ${widget.news.url}');
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch ${widget.news.url}';
    }
  }

  bool _isPaywallMessage(String? text) {
    if (text == null) return false;
    return text.trim().toLowerCase() == 'only available in paid plans';
  }

  Widget _buildArticleContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // ignore: todo
    // TODO (frontend): Replace with real subscription check when backend is available
    // ignore: unused_local_variable
    const bool isSubscriber = false;

    final bool hideContent = _isPaywallMessage(widget.news.content) || _isPaywallMessage(widget.news.description);

    // Always show a teaser/preview (max 200 chars)
    String teaser = '';
    if (!hideContent) {
      if (widget.news.content.isNotEmpty) {
        teaser = widget.news.content.length > 200
            ? '${widget.news.content.substring(0, 200)}...'
            : widget.news.content;
      } else if (widget.news.description.isNotEmpty) {
        teaser = widget.news.description.length > 200
            ? '${widget.news.description.substring(0, 200)}...'
            : widget.news.description;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hideContent && teaser.isNotEmpty)
        Text(
            teaser,
            style: textTheme.bodyMedium,
          ),
        const SizedBox(height: 16),
        // AI Summary button (now for all articles)
        ElevatedButton(
          onPressed: _showAiSummary,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[100],
            foregroundColor: Colors.amber[900],
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 22),
              SizedBox(width: 10),
              Text(
                'AI Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              SizedBox(width: 10),
              Icon(Icons.emoji_events, color: Colors.amber, size: 22),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Read Original button (always after teaser and AI Summary)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.language_rounded),
            label: const Text('Read Full article from Source'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final url = Uri.parse(widget.news.url);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.inAppWebView);
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open article.')),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        if (widget.news.metadata['isPremium'] == true ||
            widget.news.metadata['isMockData'] == true) ...[
          // Premium overlay and lock icon
          Stack(
            children: [
        Container(
                width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
                child: const SizedBox.shrink(), // No full content for premium
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFffd54f),
                        Color(0xFFff7043),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: const Row(
                    children: [
                      Icon(Icons.lock, color: Colors.white, size: 18),
                      SizedBox(width: 4),
                      Text('Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                        ),
                      ),
                    ),
                  ],
          ),
          const SizedBox(height: 16),
          // Subscription call-to-action
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Subscribe now to unlock full content and premium summaries.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Tooltip(
                  message: 'See plans & benefits',
                  child: IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.amber),
                    onPressed: () {
                      Navigator.pushNamed(context, '/subscription');
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/subscription');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Upgrade to Premium'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Like/heart button for feedback (frontend placeholder)
        Row(
          children: [
            IconButton(
              // ignore: todo
              onPressed: () {/* TODO : Implement like logic or UI feedback */},
              icon: const Icon(Icons.favorite_border),
              tooltip: 'Like this article',
            ),
            const Text('Like'),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () {
                /* Implement logic in backend */
              },
              icon: const Icon(Icons.share),
              tooltip: 'Share',
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Placeholder for comments/discussion section (frontend only)
        const Card(
          color: Color(0xFFF5F5F5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comments', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Sign in to comment and join the discussion.'),
                // Add comment list and input field when backend is available
              ],
            ),
                ),
        ),
        if (widget.news.categories.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Categories',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.news.categories.map((category) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  category,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Check if article has transliteration in metadata
    final bool hasTransliteration =
        widget.news.metadata['transliteration'] != null;

    final String? transliteratedTitle = hasTransliteration
        ? widget.news.metadata['transliteration']['title']
        : null;

    final String? transliteratedDescription = hasTransliteration
        ? widget.news.metadata['transliteration']['description']
        : null;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            expandedHeight: hasTransliteration ? 300 : 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: widget.news.imageUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        // Remove Hero widget to fix duplicate hero tag issue
                        CachedNetworkImage(
                          imageUrl: widget.news.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            margin: EdgeInsets.zero,
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            margin: EdgeInsets.zero,
                            color: colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        // Keep the positioned title text with better readability
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              widget.news.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 3.0,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(color: colorScheme.surfaceContainerHighest),
            ),
            actions: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: IconButton(
                  key: ValueKey<bool>(_isSaved),
                  icon: Icon(
                    _isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    color: _isSaved ? colorScheme.primary : null,
                    size: 28,
                  ),
                  onPressed: _handleSaveArticle,
                  tooltip: _isSaved ? 'Remove from saved' : 'Save article',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_browser_rounded, size: 28),
                onPressed: _handleOpenArticle,
                tooltip: 'Open in browser',
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              margin: const EdgeInsets.only(top: 0),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.article_rounded,
                              size: 16,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.news.source,
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(widget.news.publishedAt),
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Display transliterated title if available
                  if (transliteratedTitle != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.translate_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Transliterated Title',
                                style: textTheme.titleSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            transliteratedTitle,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  // Description
                  Text(
                    widget.news.description,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Display transliterated description if available
                  if (transliteratedDescription != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.translate_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Transliterated Description',
                                style: textTheme.titleSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            transliteratedDescription,
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  // Main content using the new method
                  _buildArticleContent(),

                  const SizedBox(height: 32),

                  // Emotion selector with better UI
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.emoji_emotions_rounded,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'How did this article make you feel?',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildEmotionSelector(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}-$month-$day';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildEmotionSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: _emotions.map((emotion) {
        final isSelected = _selectedEmotion == emotion['name'];
        return AnimatedBuilder(
          animation: _emotionController,
          builder: (context, child) {
            final scale =
                isSelected ? 1.0 + (_emotionController.value * 0.2) : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: InkWell(
            onTap: () => _selectEmotion(emotion['name']),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        colorScheme.shadow.withOpacity(isSelected ? 0.1 : 0.05),
                    blurRadius: isSelected ? 8 : 4,
                    offset: Offset(0, isSelected ? 2 : 1),
                  ),
                ],
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    emotion['icon'],
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    emotion['name'],
                    style: textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showAiSummary() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final summary = await apiService.getSummary(
        widget.news.content,
        language: widget.news.language,
      );
      Navigator.of(context).pop(); // Remove loading dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI Summary'),
          content: Text(summary['summary'] ?? summary['error'] ?? 'No summary available.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Remove loading dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to fetch summary: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}

class RecommendationsTestScreen extends StatefulWidget {
  const RecommendationsTestScreen({super.key});

  @override
  RecommendationsTestScreenState createState() => RecommendationsTestScreenState();
}

class RecommendationsTestScreenState extends State<RecommendationsTestScreen> {
  String _result = '';
  bool _loading = false;

  Future<void> _fetchRecommendations() async {
    setState(() {
      _loading = true;
      _result = '';
    });
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      // If your endpoint requires a token, provide it here
      // final token = 'YOUR_JWT_TOKEN_HERE';
      // final recommendations = await apiService.getRecommendations(token);
      final recommendations = await apiService.getRecommendations('');
      setState(() {
        _result = recommendations.toString();
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Recommendations API')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _fetchRecommendations,
              child: _loading ? const CircularProgressIndicator() : const Text('Fetch Recommendations'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_result, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
