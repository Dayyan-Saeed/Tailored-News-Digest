import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../widgets/news/news_card.dart';

class SearchScreen extends StatefulWidget {
  final List<NewsModel> allNews;
  final int userPoints;

  const SearchScreen({
    super.key,
    required this.allNews,
    required this.userPoints,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Autofocus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<NewsModel> get _filteredNews {
    if (_searchQuery.isEmpty) return [];
    final query = _searchQuery.toLowerCase();
    return widget.allNews.where((news) {
      return news.title.toLowerCase().contains(query) ||
          news.description.toLowerCase().contains(query) ||
          news.content.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNews = _filteredNews;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search for topics, locations & sources',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 18),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _controller.clear();
                  });
                },
              ),
          ],
        ),
      ),
      body: _searchQuery.isEmpty
          ? const Center(
              child: Text(
                'Type to search articles',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : filteredNews.isEmpty
              ? const Center(
                  child: Text(
                    'No articles found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredNews.length,
                  itemBuilder: (context, index) {
                    final news = filteredNews[index];
                    return NewsCard(
                      news: news,
                      onTap: () {
                        Navigator.of(context).pop();
                        // Optionally, you could navigate to detail here
                        // or use a callback to HomeScreen
                      },
                      isLocked: news.pointsRequired > widget.userPoints,
                      userPoints: widget.userPoints,
                    );
                  },
                ),
    );
  }
} 