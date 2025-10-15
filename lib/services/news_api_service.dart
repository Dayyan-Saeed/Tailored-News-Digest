import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NewsApiService {
  static Future<List<Map<String, String>>> fetchNews(
      {String category = "general"}) async {
    const String apiKey =
        "ee409d72fdae4b1f937fe529ff6a4eec"; // Replace with your actual API key
    final String url =
        "https://newsapi.org/v2/top-headlines?country=us&category=$category&apiKey=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, String>> articles = [];

        for (var article in data["articles"]) {
          articles.add({
            "title": article["title"] ?? "No title",
            "description": article["description"] ?? "No description",
            "image": article["urlToImage"] ?? "",
            "url": article["url"] ?? "",
          });
        }

        return articles;
      } else {
        throw Exception("Failed to fetch news");
      }
    } catch (e) {
      debugPrint('Error fetching news: $e');
      return [];
    }
  }
}
