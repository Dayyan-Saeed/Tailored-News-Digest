import 'package:flutter/material.dart';

class SubscriptionBottomSheet extends StatelessWidget {
  final VoidCallback? onSubscribe;
  final VoidCallback? onClose;
  final int pointsRequired;
  final int userPoints;

  const SubscriptionBottomSheet({
    super.key,
    this.onSubscribe,
    this.onClose,
    required this.pointsRequired,
    required this.userPoints,
  });

  static Future<void> show({
    required BuildContext context,
    required int pointsRequired,
    required int userPoints,
    VoidCallback? onSubscribe,
  }) {
    // Use a very simple approach with no possibility of negative margins
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SubscriptionBottomSheet(
          pointsRequired: pointsRequired,
          userPoints: userPoints,
          onSubscribe: onSubscribe,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Create a white rounded card
            Card(
              margin: const EdgeInsets.all(0),
              color: colorScheme.surface,
              elevation: 8,
              shadowColor: Colors.black38,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top section with icon
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.lock_rounded,
                          size: 40,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title section
                    Text(
                      'Premium Content',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This article requires a subscription or points to access',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Points information
                    Card(
                      elevation: 0,
                      color: colorScheme.errorContainer.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.errorContainer),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colorScheme.errorContainer,
                              child: Icon(
                                Icons.stars_rounded,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Required: ',
                                        style: textTheme.titleSmall?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        '$pointsRequired points',
                                        style: textTheme.titleSmall?.copyWith(
                                          color: colorScheme.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Your balance: ',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        '$userPoints points',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: userPoints >= pointsRequired
                                              ? colorScheme.primary
                                              : colorScheme.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Subscription options
                    Text(
                      'Choose an option',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Options as simple cards
                    _buildSimpleOption(
                      context,
                      title: 'Monthly Subscription',
                      description: 'Unlimited access to all articles',
                      price: '\$4.99/month',
                      icon: Icons.calendar_month_rounded,
                      isRecommended: true,
                    ),
                    const SizedBox(height: 12),
                    _buildSimpleOption(
                      context,
                      title: 'Annual Subscription',
                      description: 'Save 40% with yearly billing',
                      price: '\$29.99/year',
                      icon: Icons.calendar_today_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildSimpleOption(
                      context,
                      title: 'Points Package',
                      description: '500 points to spend on articles',
                      price: '\$9.99',
                      icon: Icons.stars_rounded,
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onClose,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Maybe Later'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: onSubscribe,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Subscribe Now'),
                          ),
                        ),
                      ],
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

  Widget _buildSimpleOption(
    BuildContext context, {
    required String title,
    required String description,
    required String price,
    required IconData icon,
    bool isRecommended = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: isRecommended ? 2 : 0,
      color: isRecommended ? colorScheme.primaryContainer : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isRecommended ? colorScheme.primary : colorScheme.outlineVariant,
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isRecommended
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              child: Icon(
                icon,
                color: isRecommended
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isRecommended
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'BEST VALUE',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: textTheme.bodySmall?.copyWith(
                      color: isRecommended
                          ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              price,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color:
                    isRecommended ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
