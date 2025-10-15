import 'package:flutter/material.dart';

/// Helper class for text styling, especially for multilingual support
class TextHelpers {
  /// Returns the appropriate font family for the given language
  static String getFontFamily(String language) {
    if (language == 'ur') {
      // First try our app's Urdu font, then use system fonts as fallback
      return 'NotoNastaliqUrdu, Jameel Noori Nastaleeq, Noto Nastaliq Urdu, Alvi Nastaleeq, Nastaleeq, Arial';
    }
    return 'Poppins'; // Default font
  }

  /// Returns the appropriate text direction for the given language
  static TextDirection getTextDirection(String language) {
    if (language == 'ur') {
      return TextDirection.rtl;
    }
    return TextDirection.ltr;
  }

  /// Returns a TextStyle for Urdu text with appropriate settings
  static TextStyle getUrduTextStyle({
    double fontSize = 16.0,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double height = 1.5,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontFamily: getFontFamily('ur'),
    );
  }

  /// Creates a widget that displays both Urdu text and its transliteration
  /// This ensures content is readable even if Urdu fonts are not rendering properly
  static Widget buildBilingualText({
    required String urduText,
    required String transliteration,
    TextStyle? urduStyle,
    TextStyle? transliterationStyle,
    int? maxLines,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Urdu text with RTL direction
        Text(
          urduText,
          style: urduStyle ?? getUrduTextStyle(),
          maxLines: maxLines,
          overflow: overflow,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 4),
        // Transliteration in Latin script (more compatible)
        Text(
          transliteration,
          style: transliterationStyle ??
              TextStyle(
                fontSize: (urduStyle?.fontSize ?? 16) - 2,
                color: urduStyle?.color,
                fontStyle: FontStyle.italic,
              ),
          maxLines: maxLines,
          overflow: overflow,
        ),
      ],
    );
  }
}
