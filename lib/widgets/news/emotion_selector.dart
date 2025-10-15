import 'package:flutter/material.dart';

class EmotionSelector extends StatelessWidget {
  final Map<String, int> emotions;
  final Function(String emotion) onEmotionSelected;
  final bool isReadOnly;

  const EmotionSelector({
    super.key,
    required this.emotions,
    required this.onEmotionSelected,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final emotionIcons = {
      'happy': Icons.sentiment_satisfied,
      'sad': Icons.sentiment_dissatisfied,
      'angry': Icons.sentiment_very_dissatisfied,
      'surprised': Icons.sentiment_satisfied_alt,
      'neutral': Icons.sentiment_neutral,
    };

    final emotionColors = {
      'happy': Colors.amber,
      'sad': Colors.blue,
      'angry': Colors.red,
      'surprised': Colors.purple,
      'neutral': Colors.grey,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How do you feel about this article?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: emotionIcons.entries.map((entry) {
            final emotion = entry.key;
            final icon = entry.value;
            final count = emotions[emotion] ?? 0;
            final color = emotionColors[emotion] ?? Colors.grey;

            return InkWell(
              onTap: isReadOnly ? null : () => onEmotionSelected(emotion),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      emotion.capitalize(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($count)',
                      style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
