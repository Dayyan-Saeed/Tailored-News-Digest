import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/news_service.dart';
import '../models/news_model.dart';
import '../models/user_model.dart';
import '../widgets/news/news_card.dart';
import '../utils/logger.dart';
import 'news_detail_screen.dart';
import 'profile_screen.dart';
import 'recommendations_screen.dart';
import '../utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _newsService = NewsService();
  final _authService = AuthService();
  String _selectedCategory = 'All';
  String _selectedLanguage = 'en';
  bool _isLoading = false;
  List<NewsModel> _news = [];
  UserModel? _user;
  late TabController _tabController;

  final List<String> _categories = [
    'All',
    'Business',
    'Entertainment',
    'General',
    'Health',
    'Science',
    'Sports',
    'Technology',
  ];

  final _random = Random();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _loadNews();

    // Initialize selected language from ThemeProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _selectedLanguage = themeProvider.language;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        _user = await _authService.getUserData(user.uid);
        setState(() {});
      }
    } catch (e) {
      logger.e('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: $e')),
        );
      }
    }
  }

  Future<void> _loadNews() async {
    setState(() => _isLoading = true);
    _news = []; // Clear existing news before loading

    try {
      logger.i(
          'Loading news with category: $_selectedCategory, language: $_selectedLanguage');


      if (_selectedLanguage == 'ur') {
        // URDU NEWS HANDLING - always try real content first, then fall back to mock
        try {
          // Try to fetch real Urdu news (with or without category as appropriate)
          final news = _selectedCategory == 'All'
              ? await _newsService.fetchRealUrduNews(null)
              : await _newsService.fetchRealUrduNews(_selectedCategory);

          if (news.isNotEmpty) {
            logger.i(
                'Successfully loaded ${news.length} real Urdu news articles');
            setState(() => _news = news);
          } else {
            logger.w('No real Urdu news found, falling back to mock data');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'No real articles available. Showing sample Urdu content.'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                ),
              );
            }

            // Load mock Urdu data
            setState(() => _news = _newsService.generateMockUrduNews(
                _selectedCategory == 'All' ? null : _selectedCategory));
          }
        } catch (e) {
          logger.e('Error loading Urdu news: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Unable to load real Urdu news. Showing sample content.'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.orange,
              ),
            );
          }
          // Load mock Urdu data as fallback
          setState(() => _news = _newsService.generateMockUrduNews(
              _selectedCategory == 'All' ? null : _selectedCategory));
        }
      } else {
        // ENGLISH NEWS HANDLING - real or mock
        try {
          List<NewsModel> news = [];

          try {
            // Try fetching from API first
            news = await _newsService.fetchNews(
              category: _selectedCategory == 'All' ? null : _selectedCategory,
              language: 'en',
            );
          } catch (apiError) {
            logger.e('API Error: $apiError');
            news = [];
          }

          if (news.isEmpty) {
            logger.w('No English news found from API, using mock data');
            news = _generateMockEnglishNews();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Using sample content for demonstration purposes.'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }

          setState(() => _news = news);
        } catch (e) {
          logger.e('Error in English news flow: $e');
          setState(() => _news = _generateMockEnglishNews());
        }
      }
    } catch (e) {
      logger.e('Error loading news: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e. Using sample content.'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Fall back to appropriate mock data based on selected language
      setState(() => _news = _selectedLanguage == 'ur'
          ? _newsService.generateMockUrduNews(
              _selectedCategory == 'All' ? null : _selectedCategory)
          : _generateMockEnglishNews());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadNews();
  }

  void _handleNewsTap(NewsModel news) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(news: news),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      logger.e('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchScreen(
                  allNews: _news,
                  userPoints: _user?.points ?? 0,
                ),
              ),
            );
          },
        ),
        title: const Text('Tailored News Digest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.newspaper),
              text: 'News Feed',
            ),
            Tab(
              icon: Icon(Icons.recommend),
              text: 'For You',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // News feed tab
          _buildNewsFeed(),

          // Recommendations tab
          const RecommendationsScreen(),
        ],
      ),
    );
  }

  Widget _buildNewsFeed() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Categories
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedCategory = category);
                          _loadNews();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSelected ? Colors.blue : Colors.grey.shade200,
                          foregroundColor:
                              isSelected ? Colors.white : Colors.black,
                        ),
                        child: Text(category),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Language selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Language: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'ur', child: Text('Urdu')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedLanguage = value);

                        // Update theme provider with the new language
                        final themeProvider =
                            Provider.of<ThemeProvider>(context, listen: false);
                        themeProvider.setLanguage(value);

                        _loadNews();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        // News feed
        Expanded(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading news articles...'),
                    ],
                  ),
                )
              : _news.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _selectedLanguage == 'ur'
                                ? 'No Urdu news available for "$_selectedCategory" category.\nTry another category.'
                                : 'No news available.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _handleRefresh,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _news.length,
                        itemBuilder: (context, index) {
                          final news = _news[index];
                          return NewsCard(
                            news: news,
                            onTap: () => _handleNewsTap(news),
                            isLocked:
                                news.pointsRequired > (_user?.points ?? 0),
                            userPoints: _user?.points ?? 0,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // Generate mock English news as fallback
  List<NewsModel> _generateMockEnglishNews() {
    logger.i('Generating mock English news for category: $_selectedCategory');
    final DateTime now = DateTime.now();

    final List<NewsModel> allNews = [
      NewsModel(
        id: 'en-news-1',
        title: 'New Advancements in AI Technology Reshape Industry',
        description:
            'Researchers announce breakthrough in machine learning algorithms that could revolutionize how AI systems learn and adapt.',
        content:
            'Recent developments in artificial intelligence have led to significant breakthroughs in how machines learn and process information. The new approach, developed by a team of international researchers, allows AI systems to learn more efficiently with less data and adapt more quickly to new situations.',
        url: 'https://example.com/ai-breakthrough',
        imageUrl:
            'https://images.unsplash.com/photo-1677442136019-21780ecad0f6',
        source: 'Tech Today',
        publishedAt: now.subtract(const Duration(hours: 2)),
        language: 'en',
        categories: ['Technology'],
        metadata: {
          'isRealNews': false,
          'provider': 'MockData',
          'reliability': 'demo',
          'transliteration': {
            'title':
                'AI Technology mein naye taraqqi se industry tabdeel ho rahi hai',
            'description':
                'Machine learning algorithms mein breakthrough ka elaan jis se AI systems ki learning aur adaptation badal sakti hai'
          }
        },
      ),
      NewsModel(
        id: 'en-news-2',
        title: 'Global Markets Respond to Economic Policy Changes',
        description:
            'Major stock indices show volatility as central banks announce interest rate adjustments.',
        content:
            'Financial markets around the world saw significant movement today as several major central banks announced adjustments to their monetary policies. The changes, which include modified interest rates and updated economic forecasts, have prompted investors to reassess their positions.',
        url: 'https://example.com/market-response',
        imageUrl:
            'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3',
        source: 'Financial Times',
        publishedAt: now.subtract(const Duration(hours: 5)),
        language: 'en',
        categories: ['Business'],
        metadata: {
          'isRealNews': false,
          'provider': 'MockData',
          'reliability': 'demo',
          'transliteration': {
            'title':
                'Global markets ka economic policy tabdeelion par radd-e-amal',
            'description':
                'Markazi banks ke sood rate mein tabdeeli ke elaan par bade stock indices mein utaar-chadhav'
          }
        },
      ),
      NewsModel(
        id: 'en-news-3',
        title:
            'Scientific Breakthrough: New Renewable Energy Source Discovered',
        description:
            'Scientists reveal innovative approach to clean energy generation with higher efficiency than current technologies.',
        content:
            'A team of scientists has announced the discovery of a new method for generating renewable energy that could significantly outperform existing technologies. The breakthrough, which utilizes a previously unexplored natural process, has the potential to provide clean energy at a much higher efficiency rate.',
        url: 'https://example.com/energy-breakthrough',
        imageUrl:
            'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e',
        source: 'Science Daily',
        publishedAt: now.subtract(const Duration(hours: 8)),
        language: 'en',
        categories: ['Science'],
        metadata: {
          'isRealNews': false,
          'provider': 'MockData',
          'reliability': 'demo',
          'transliteration': {
            'title':
                'Scienci breakthrough: Qabil-e-tajdeed tawanai ka naya zariya daryaft',
            'description':
                'Scientists ne saaf tawanai paida karne ke liye innovative tareeqa bataya jo moujuda technology se ziada muassar hai'
          }
        },
      ),
      NewsModel(
        id: 'en-news-4',
        title: 'Major Health Study Reveals New Insights into Preventative Care',
        description:
            'Comprehensive research shows significant benefits of early intervention and lifestyle adjustments in preventing chronic diseases.',
        content:
            'A landmark health study involving more than 100,000 participants over a decade has revealed crucial insights into how preventative healthcare measures can dramatically reduce the risk of developing chronic conditions. The research highlights the importance of early screening and lifestyle modifications.',
        url: 'https://example.com/health-study',
        imageUrl:
            'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7',
        source: 'Health Journal',
        publishedAt: now.subtract(const Duration(hours: 12)),
        language: 'en',
        categories: ['Health'],
        metadata: {
          'isRealNews': false,
          'provider': 'MockData',
          'reliability': 'demo',
          'transliteration': {
            'title':
                'Bari sehat study ne hifazati dekhbhal ke naye nuqat-e-nazar zahir kiye',
            'description':
                'Jamia research se pata chala hai ke waqt par mudakhalat aur zindagi ke andaz mein tabdeeli se muzmin amraaz se bachao mumkin hai'
          }
        },
      ),
      NewsModel(
        id: 'en-news-5',
        title: 'International Sports Championship Breaks Viewership Records',
        description:
            'Global audience for championship finals exceeds all previous records, setting new benchmark for sports broadcasting.',
        content:
            'The recently concluded international sports championship has set new records for global viewership, with preliminary data indicating that more than 2 billion people watched the finals across various platforms. This unprecedented level of engagement highlights the growing global appeal of the sport.',
        url: 'https://example.com/sports-viewership',
        imageUrl:
            'https://images.unsplash.com/photo-1461896836934-ffe607ba8211',
        source: 'Sports Network',
        publishedAt: now.subtract(const Duration(hours: 15)),
        language: 'en',
        categories: ['Sports'],
        metadata: {
          'isRealNews': false,
          'provider': 'MockData',
          'reliability': 'demo',
          'transliteration': {
            'title':
                'Bain-ul-aqwami khel championship ne nazreen ke record tord diye',
            'description':
                'Championship finals ke liye global audience ne tamam sabqa record tor diye, sports broadcasting ke liye naya benchmark qaim ho gaya'
          }
        },
      ),
      NewsModel(
        id: 'en-news-6',
        title:
            'Entertainment Industry Embraces New Digital Distribution Models',
        description:
            'Major studios announce shift toward direct-to-consumer platforms, reshaping how content reaches audiences.',
        content:
            'Several major entertainment studios have announced significant changes to their distribution strategies, placing greater emphasis on direct-to-consumer digital platforms. This industry-wide shift represents a fundamental change in how entertainment content is delivered to audiences around the world.',
        url: 'https://example.com/entertainment-digital',
        imageUrl:
            'https://images.unsplash.com/photo-1598899134739-24c46f58b8c0',
        source: 'Entertainment Weekly',
        publishedAt: now.subtract(const Duration(hours: 18)),
        language: 'en',
        categories: ['Entertainment'],
        metadata: {
          'isRealNews': false,
          'provider': 'MockData',
          'reliability': 'demo',
          'transliteration': {
            'title':
                'Entertainment industry ne naye digital taqseem ke models apna liye',
            'description':
                'Bade studios ne baraah-e-raast sarif ke platforms ki taraf shift ka elaan kiya, jis se muhtawiyat ke nazreen tak pohunchne ka tareqa badal raha hai'
          }
        },
      ),
      NewsModel(
        id: 'en-news-7',
        title: 'Climate Initiative Gains International Support',
        description:
            'New multinational agreement pledges significant resources to address climate challenges.',
        content:
            'A coalition of countries has announced a comprehensive new climate initiative that includes substantial funding commitments and policy coordination. The agreement, which represents one of the most ambitious international climate efforts to date, aims to accelerate the transition to sustainable energy sources and reduce global carbon emissions.',
        url: 'https://example.com/climate-initiative',
        imageUrl:
            'https://images.unsplash.com/photo-1593829266619-143c5f7be30f',
        source: 'Global News',
        publishedAt: now.subtract(const Duration(hours: 22)),
        language: 'en',
        categories: ['General'],
        metadata: {
          'isRealNews': false,
          'provider': 'MockData',
          'reliability': 'demo',
          'transliteration': {
            'title': 'Climate initiative ko bain-ul-aqwami himayat hasil hui',
            'description':
                'Naye kaseer-ul-mulki muahide mein climate challenges se nipatne ke liye ahem wasail ka wada kiya gaya hai'
          }
        },
      ),
    ];

    // Filter news by category if a specific category is selected (and not "All")
    if (_selectedCategory.toLowerCase() != 'all') {
      final filteredNews = allNews
          .where((news) => news.categories.contains(_selectedCategory))
          .toList();

      // Return filtered news if not empty, otherwise return all news
      return filteredNews.isNotEmpty ? filteredNews : allNews;
    }

    return allNews;
  }

  String getFallbackImage(String category) {
    final generalImages = [
      'assets/images/news_placeholder1.png',
      'assets/images/news_placeholder2.png',
      'assets/images/news_placeholder3.png',
    ];
    final sportsImages = [
      'assets/images/sports_placeholder1.png',
      'assets/images/sports_placeholder2.png',
    ];
    final businessImages = [
      'assets/images/business_placeholder1.png',
      'assets/images/business_placeholder2.png',
    ];

    switch (category.toLowerCase()) {
      case 'sports':
        return sportsImages[_random.nextInt(sportsImages.length)];
      case 'business':
        return businessImages[_random.nextInt(businessImages.length)];
      default:
        return generalImages[_random.nextInt(generalImages.length)];
    }
  }
}
