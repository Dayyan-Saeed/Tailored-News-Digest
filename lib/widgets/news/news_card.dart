import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/news_model.dart';
import '../../utils/logger.dart';
import '../../utils/text_helpers.dart';
import '../paywall/subscription_sheet.dart';

class NewsCard extends StatefulWidget {
  final NewsModel news;
  final VoidCallback onTap;
  final bool isLocked;
  final int userPoints;

  const NewsCard({
    super.key,
    required this.news,
    required this.onTap,
    this.isLocked = false,
    this.userPoints = 0,
  });

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openOriginalArticle(BuildContext context) async {
    try {
      // Check if this is mock data
      bool isMockData = (widget.news.metadata['isMockData'] == true ||
          widget.news.metadata['provider'] == 'MockNewsService');

      if (isMockData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('This is sample content. No external article available.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (widget.news.url.isEmpty) {
        throw 'No URL available for this article';
      }

      // Open directly in external browser - bypassing WebView
      await _openInExternalBrowser();
    } catch (e) {
      // Log the error but don't show UI since this is just a card
      logger.e('Error opening URL: $e');
      if (mounted) {
        // ignore: use_build_context_synchronously
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
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch ${widget.news.url}';
    }
  }

  void _handleCardTap() {
    if (widget.isLocked) {
      // Use the new simplified dialog approach to avoid margin issues
      SubscriptionBottomSheet.show(
        context: context,
        pointsRequired: widget.news.pointsRequired,
        userPoints: widget.userPoints,
      );
    } else {
      // Use a safer navigation approach with MaterialPageRoute to ensure proper transitions
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is mock data
    final bool isMockData = (widget.news.metadata['isMockData'] == true ||
        widget.news.metadata['provider'] == 'MockNewsService');

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            onTap: _handleCardTap,
            child: Container(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.news.imageUrl.isNotEmpty)
                        Stack(
                          children: [
                            Hero(
                              tag: 'news_image_${widget.news.id}',
                              child: Material(
                                type: MaterialType.transparency,
                                child: SizedBox(
                                  height: 200,
                                  width: double.infinity,
                                  child: CachedNetworkImage(
                                    imageUrl: widget.news.imageUrl.isNotEmpty
                                        ? widget.news.imageUrl
                                        : getFallbackImage(widget.news.categories.isNotEmpty ? widget.news.categories.first : ''),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      margin: EdgeInsets.zero,
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: colorScheme.primary,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      margin: EdgeInsets.zero,
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.isLocked)
                              Container(
                                height: 200,
                                width: double.infinity,
                                margin: EdgeInsets.zero,
                                color: Colors.black.withOpacity(0.6),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer
                                              .withOpacity(0.9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.lock,
                                          color: colorScheme.onPrimaryContainer,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest
                                              .withOpacity(0.9),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${widget.news.pointsRequired} points required',
                                              style: textTheme.labelLarge
                                                  ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'You have ${widget.userPoints} points',
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Demo indicator with improved design
                            if (isMockData)
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade700,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Sample',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.news.source,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(widget.news.publishedAt),
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildNewsTitle(),
                            const SizedBox(height: 8),
                            _buildNewsDescription(),
                            const SizedBox(height: 16),
                            _buildFooter(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsTitle() {
    final textTheme = Theme.of(context).textTheme;

    // If this is Urdu news and has transliteration, show both
    if (widget.news.language == 'ur' &&
        widget.news.metadata['transliteration'] != null &&
        widget.news.metadata['transliteration']['title'] != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Urdu title
          Text(
            widget.news.title,
            style: TextHelpers.getUrduTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 4),
          // Transliteration in Latin script (more compatible)
          Text(
            widget.news.metadata['transliteration']['title'],
            style: textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    // Default case: just show the title with appropriate styling
    return Text(
      widget.news.title,
      style: widget.news.language == 'ur'
          ? TextHelpers.getUrduTextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )
          : textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textDirection: TextHelpers.getTextDirection(widget.news.language),
    );
  }

  Widget _buildNewsDescription() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // If this is Urdu news and has transliteration, show both
    if (widget.news.language == 'ur' &&
        widget.news.metadata['transliteration'] != null &&
        widget.news.metadata['transliteration']['description'] != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Urdu description
          Text(
            widget.news.description,
            style: TextHelpers.getUrduTextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 4),
          // Transliteration in Latin script (more compatible)
          Text(
            widget.news.metadata['transliteration']['description'],
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    // Default case: just show the description with appropriate styling
    return Text(
      widget.news.description,
      style: widget.news.language == 'ur'
          ? TextHelpers.getUrduTextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            )
          : textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textDirection: TextHelpers.getTextDirection(widget.news.language),
    );
  }

  Widget _buildFooter() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        // Categories with improved design
        if (widget.news.categories.isNotEmpty)
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.news.categories.map((category) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // Source link with better visual
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openOriginalArticle(context),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.link_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),

        // Points indicator with enhanced design
        if (widget.news.pointsRequired > 0)
          Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.news.pointsRequired}',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String getFallbackImage(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return 'assets/images/sports_placeholder.png';
      case 'business':
        return 'assets/images/business_placeholder.png';
      // Add more categories as needed
      default:
        return 'assets/images/news_placeholder.png';
    }
  }
}
