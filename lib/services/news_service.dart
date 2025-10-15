import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/news_model.dart';
import '../utils/logger.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html_unescape/html_unescape.dart';
import 'package:logger/logger.dart';

class NewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _apiKey = dotenv.get('NEWS_API_KEY', fallback: '');
  final String _baseUrl = 'https://newsapi.org/v2';
  final Logger _logger = Logger();

  get t => null;

  // Fetch news from NewsAPI
  Future<List<NewsModel>> fetchNews({
    String? category,
    String? language,
    int pageSize = 20,
    bool saveToFirestore = true,
  }) async {
    try {
      logger.i(
          'Attempting to fetch news, language: ${language ?? "en"}, category: ${category ?? "All"}');

      // Handle Urdu language specially
      if (language == 'ur') {
        logger.i('Fetching Urdu news');
        return await _fetchUrduNews(category, pageSize, saveToFirestore);
      }

      // For English news, try NewsData.io first as the main source
      try {
        logger.i('Trying NewsData.io API for English news (primary source)');
        final newsDataResults = await _fetchFromNewsDataApiForEnglish(category);
        if (newsDataResults.isNotEmpty) {
          logger.i(
              'Successfully fetched ${newsDataResults.length} English articles from NewsData.io');

          // Save to Firestore if requested
          if (saveToFirestore) {
            _saveArticlesToFirestore(newsDataResults);
          }

          return newsDataResults;
        }
      } catch (e) {
        logger.e('Error fetching from NewsData.io: $e');
      }

      // Try GNews API as fallback
      try {
        logger.i('Trying GNews API for English news (fallback)');
        final gNewsEnglish = await _fetchFromGNewsApiForEnglish(category);
        if (gNewsEnglish.isNotEmpty) {
          logger.i(
              'Successfully fetched ${gNewsEnglish.length} English articles from GNews');

          // Save to Firestore if requested
          if (saveToFirestore) {
            _saveArticlesToFirestore(gNewsEnglish);
          }

          return gNewsEnglish;
        }
      } catch (e) {
        logger.e('Error fetching from GNews: $e');
      }

      // Try NewsAPI as last resort
      try {
        logger.i('Trying NewsAPI for English news (last resort)');
        final newsApiResults = await _fetchFromNewsAPIForEnglish(category);
        if (newsApiResults.isNotEmpty) {
          logger.i(
              'Successfully fetched ${newsApiResults.length} English articles from NewsAPI');

          // Save to Firestore if requested
          if (saveToFirestore) {
            _saveArticlesToFirestore(newsApiResults);
          }

          return newsApiResults;
        }
      } catch (e) {
        logger.e('Error fetching from NewsAPI: $e');
      }

      // If no real news sources returned articles, generate mock data
      logger.w(
          'All real news API attempts failed, generating mock English news data');
      return _generateMockEnglishNews(category);
    } catch (e) {
      logger.e('Exception in fetchNews: $e');
      // Always provide some content by returning mock data
      return _generateMockEnglishNews(category);
    }
  }

  // Generate mock English news for when APIs are unavailable
  List<NewsModel> _generateMockEnglishNews(String? category) {
    logger.w(
        'Generating mock English news data for category: ${category ?? "All"}');

    final List<Map<String, dynamic>> mockNews = [
      {
        'title':
            'Breakthrough in AI Technology Promises Enhanced User Experience',
        'description':
            'A new AI algorithm has been developed that can adapt to user preferences with minimal data input.',
        'content':
            '[THIS IS SAMPLE CONTENT - Real news sources are currently unavailable]\n\nResearchers at a leading tech institute have announced a breakthrough in AI technology that could revolutionize how applications interact with users. The new algorithm, dubbed "AdaptiveUI", requires significantly less training data than current models while delivering more personalized results.\n\n"This represents a major step forward in making AI more accessible and effective," said lead researcher Dr. Emily Chen. "With AdaptiveUI, applications can provide truly personalized experiences without extensive data collection."\n\nThe technology is expected to be available for commercial licensing within the next six months.',
        'url': 'https://www.theverge.com/ai-artificial-intelligence',
        'imageUrl':
            'https://images.unsplash.com/photo-1677442135133-4da2987d448d',
        'source': 'Sample Tech News',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 2)),
        'category': 'Technology',
      },
      {
        'title': 'Economic Policy Changes Set to Impact Global Markets',
        'description':
            'Major economic powers announce coordinated policy changes aimed at stabilizing inflation and promoting sustainable growth.',
        'content':
            '[THIS IS SAMPLE CONTENT - Real news sources are currently unavailable]\n\nFinance ministers from G20 nations have announced a series of coordinated policy changes designed to address persistent inflation while supporting continued economic growth. The measures include adjusted interest rate targets and modified regulatory frameworks for international transactions.\n\n"These changes represent a balanced approach to our current economic challenges," said International Monetary Fund Director Kristalina Georgieva. "By acting together, we can achieve greater stability while minimizing negative impacts on vulnerable economies."\n\nMarket analysts predict initial volatility as traders adjust to the new policies, but most expect medium-term benefits across global markets.',
        'url': 'https://www.ft.com/markets',
        'imageUrl':
            'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3',
        'source': 'Sample Business News',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 5)),
        'category': 'Business',
      },
      {
        'title':
            'Renewable Energy Milestone: Solar Efficiency Exceeds 30% in Commercial Panels',
        'description':
            'New manufacturing technique enables mass production of high-efficiency solar panels at competitive prices.',
        'content':
            '[THIS IS SAMPLE CONTENT - Real news sources are currently unavailable]\n\nA renewable energy company has announced that its latest solar panels have achieved efficiency ratings exceeding 30%, a significant improvement over the 20-25% efficiency typical of current commercial panels. The company credits a new manufacturing process that allows for better crystal alignment in silicon cells.\n\nIndustry experts consider 30% efficiency a key milestone for making solar more competitive with traditional energy sources without subsidies. "These panels generate nearly 50% more electricity from the same surface area," said energy analyst Maria Rodriguez. "That dramatically improves the economics of solar installations."\n\nProduction is expected to scale up over the next year, with panels becoming widely available by Q2 2023.',
        'url': 'https://www.scientificamerican.com/energy/',
        'imageUrl':
            'https://images.unsplash.com/photo-1508514177221-188b1cf16e9d',
        'source': 'Sample Science News',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 7)),
        'category': 'Science',
      },
      {
        'title':
            'Health Study Reveals Benefits of Intermittent Movement Breaks During Work Day',
        'description':
            'Brief movement breaks every 30 minutes may offset negative health effects of prolonged sitting.',
        'content':
            '[THIS IS SAMPLE CONTENT - Real news sources are currently unavailable]\n\nA comprehensive health study following 5,000 office workers over three years has found that incorporating brief movement breaks into the workday significantly reduces risks associated with sedentary behavior. Participants who took 2-3 minute breaks every 30 minutes showed improved cardiovascular health markers and reduced back pain compared to those who sat for longer uninterrupted periods.\n\n"These findings are particularly relevant given how many people now work from home, often with less movement than in traditional office settings," said study director Dr. James Miller. "The good news is that the movement doesn\'t need to be intense exercise - just standing and walking briefly provides benefits."\n\nThe researchers recommend setting timers as reminders for movement breaks and incorporating simple routines that can be done in a small space.',
        'url': 'https://www.health.harvard.edu/',
        'imageUrl':
            'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b',
        'source': 'Sample Health News',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 10)),
        'category': 'Health',
      },
      {
        'title':
            'National Football League Announces Expanded International Series',
        'description':
            'Popular sports league adds four new international venues to its regular season schedule starting next year.',
        'content':
            '[THIS IS SAMPLE CONTENT - Real news sources are currently unavailable]\n\nThe National Football League has announced an expanded international series that will include games in Berlin, Rio de Janeiro, Madrid, and Sydney starting next season. This expansion brings the total number of international games per season to ten, marking the league\'s most significant global push to date.\n\n"Fan enthusiasm for NFL games outside the United States has been extraordinary," said league commissioner Roger Goodell. "These new venues allow us to connect with even more international fans while showcasing our sport on a truly global stage."\n\nTeams scheduled to play internationally will be announced during the regular schedule release in April, with priority given to teams that have not played overseas recently.',
        'url': 'https://www.si.com/nfl/',
        'imageUrl':
            'https://images.unsplash.com/photo-1566577739112-5180d4bf9390',
        'source': 'Sample Sports News',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 14)),
        'category': 'Sports',
      },
      {
        'title':
            'Entertainment Industry Shifts as Digital Distribution Becomes Primary Revenue Source',
        'description':
            'Major studios announce reorganization to prioritize direct-to-consumer digital content delivery.',
        'content':
            '[THIS IS SAMPLE CONTENT - Real news sources are currently unavailable]\n\nSeveral major entertainment studios have announced organizational changes that position digital distribution channels as their primary focus for future content. The shift comes as streaming services now account for over 70% of content consumption across film and television media.\n\n"We\'re adapting to how audiences prefer to access entertainment," said Universal Media Group CEO Amanda Peterson. "This reorganization puts digital distribution at the center of our strategy rather than treating it as a secondary channel."\n\nThe changes include new divisions focused on interactive and on-demand content, suggesting that traditional release windows and formats may continue to evolve. Industry analysts note that theatrical releases will remain important for certain types of films, but will increasingly serve marketing and prestige functions rather than being the primary revenue source.',
        'url': 'https://www.hollywoodreporter.com/business/',
        'imageUrl':
            'https://images.unsplash.com/photo-1611162616475-46b635cb6868',
        'source': 'Sample Entertainment News',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 18)),
        'category': 'Entertainment',
      },
      {
        'title':
            'Climate Initiative to Plant 100 Million Trees Launches with Corporate Backing',
        'description':
            'Global coalition of businesses commits funding and resources to major reforestation project.',
        'content':
            '[THIS IS SAMPLE CONTENT - Real news sources are currently unavailable]\n\nA coalition of multinational corporations has announced a joint initiative to plant 100 million trees over the next five years across regions affected by deforestation. The project, called "Forest Forward," has secured initial funding of 500 million, with participating companies also committing employee volunteer hours and logistical support.\n\n"This initiative combines immediate carbon benefits with long-term ecosystem restoration," said environmental scientist Dr. Robert Zhang, who helped design the program. "We\'re focusing on native species and community involvement to ensure these forests thrive for generations."\n\nPlanting will begin next month in Brazil, Indonesia, and Kenya, with additional countries to be added in subsequent phases. The initiative will employ local workers and use satellite monitoring to track progress and forest health.',
        'url': 'https://www.nytimes.com/section/climate',
        'imageUrl':
            'https://images.unsplash.com/photo-1564589989148-4409a3e2c400',
        'source': 'Sample General News',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 22)),
        'category': 'General',
      },
    ];

    // Filter by category if specified
    List<Map<String, dynamic>> filteredNews = mockNews;
    if (category != null && category.toLowerCase() != 'all') {
      filteredNews = mockNews
          .where((news) =>
              news['category'].toLowerCase() == category.toLowerCase())
          .toList();

      // If no articles found for the category, return all news
      if (filteredNews.isEmpty) {
        logger.w(
            'No mock articles found for category $category, returning all mock news');
        filteredNews = mockNews;
      }
    }

    // Convert to NewsModel objects
    return filteredNews.map((news) {
      final mockNewsItem = NewsModel(
        id: 'mock-en-${news['title'].hashCode}',
        title: news['title'],
        description: news['description'],
        content: news['content'],
        url: news['url'],
        imageUrl: validateImageUrl(
            news['imageUrl'], news['category'], 'MockNewsService'),
        source: news['source'],
        publishedAt: news['publishedAt'] as DateTime,
        language: 'en',
        categories: [news['category']],
        metadata: {
          'isMockData': true,
          'provider': 'MockNewsService',
          'disclaimer': 'This is sample content for demonstration purposes',
          'openableUrl': true,
        },
      );
      return mockNewsItem;
    }).toList();
  }

  // Special method to fetch Urdu news
  Future<List<NewsModel>> _fetchUrduNews(
    String? category,
    int pageSize,
    bool saveToFirestore,
  ) async {
    try {
      logger.i('Fetching Urdu news with category: ${category ?? "All"}');

      // First try to fetch from NewsData.io for Urdu content
      try {
        logger.i('Trying NewsData.io API for Urdu news (primary source)');
        final newsDataResults = await _fetchFromNewsDataApi(category);
        if (newsDataResults.isNotEmpty) {
          logger.i(
              'Successfully fetched ${newsDataResults.length} Urdu articles from NewsData.io');

          // Save to Firestore if needed
          if (saveToFirestore) {
            _saveArticlesToFirestore(newsDataResults);
          }

          return newsDataResults;
        } else {
          logger.w('No Urdu articles found from NewsData.io');
        }
      } catch (e) {
        logger.e('Error fetching Urdu news from NewsData.io: $e');
      }

      // Try UrduPoint API as secondary source
      try {
        logger.i('Trying UrduPoint API for Urdu news (secondary source)');
        final urduPointNews = await _fetchFromUrduPointApi(category);
        if (urduPointNews.isNotEmpty) {
          logger.i(
              'Successfully fetched ${urduPointNews.length} articles from UrduPoint API');

          // Save to Firestore if needed
          if (saveToFirestore) {
            _saveArticlesToFirestore(urduPointNews);
          }

          return urduPointNews;
        } else {
          logger.w('No Urdu articles found from UrduPoint API');
        }
      } catch (e) {
        logger.e('Error fetching from UrduPoint API: $e');
      }

      // Try GNews API as tertiary source
      try {
        logger.i('Trying GNews API for Urdu news (tertiary source)');
        final gNewsResults = await _fetchFromGNewsApi(category);
        if (gNewsResults.isNotEmpty) {
          logger.i(
              'Successfully fetched ${gNewsResults.length} Urdu articles from GNews');

          if (saveToFirestore) {
            _saveArticlesToFirestore(gNewsResults);
          }

          return gNewsResults;
        } else {
          logger.w('No Urdu articles found from GNews API');
        }
      } catch (e) {
        logger.e('Error fetching from GNews API for Urdu: $e');
      }

      // If all real sources fail, try NewsAPI as a last resort
      // First, try searching for Urdu content
      final queryParams = {
        'apiKey': _apiKey,
        'pageSize': pageSize.toString(),
        'q': 'Pakistan OR اردو OR پاکستان', // Search for Urdu related terms
        'sortBy': 'publishedAt',
      };

      // Only add category to query if it's not null and not 'All'
      if (category != null && category.toLowerCase() != 'all') {
        queryParams['q'] = '${queryParams['q']} AND ${category.toLowerCase()}';
      }

      final uri = Uri.parse('$_baseUrl/everything').replace(
        queryParameters: queryParams,
      );

      logger.i(
          'Fetching Urdu news from NewsAPI (last resort): ${uri.toString()}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Use UTF-8 decoding for proper character handling
        final String utfDecodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(utfDecodedBody);
        final articles = data['articles'] as List;

        final newsList = articles.map((article) {
          return NewsModel(
            id: article['url'] ?? '',
            title: article['title'] ?? '',
            description: article['description'] ?? '',
            content: article['content'] ?? '',
            url: article['url'] ?? '',
            imageUrl: article['urlToImage'] ?? '',
            source: article['source']['name'] ?? '',
            publishedAt: DateTime.parse(
                article['publishedAt'] ?? DateTime.now().toIso8601String()),
            language: 'ur',
          );
        }).toList();

        if (newsList.isEmpty) {
          logger.w('No Urdu articles found from NewsAPI, using mock data');
          final mockNews = generateMockUrduNews(category);

          // Save mock news to Firestore if needed
          if (saveToFirestore) {
            _saveArticlesToFirestore(mockNews);
          }

          return mockNews;
        }

        // Save articles to Firestore if requested
        if (saveToFirestore) {
          _saveArticlesToFirestore(newsList);
        }

        return newsList;
      } else {
        logger.e('Error response from NewsAPI: ${response.body}');
        logger.w('Using mock Urdu news data due to API errors');
        final mockNews = generateMockUrduNews(category);

        // Save mock news to Firestore if needed
        if (saveToFirestore) {
          _saveArticlesToFirestore(mockNews);
        }

        return mockNews;
      }
    } catch (e) {
      logger.e('Exception in _fetchUrduNews: $e');
      logger.w('Using mock Urdu news data due to exception');
      return generateMockUrduNews(category);
    }
  }

  // Backup method to fetch from known Urdu news sources
  // ignore: unused_element
  Future<List<NewsModel>> _fetchFromUrduSources(
    String? category,
    int pageSize,
  ) async {
    try {
      // Define sources that have Urdu news
      const sources = 'geo-news,dawn-news,ary-news';

      final queryParams = {
        'apiKey': _apiKey,
        'pageSize': pageSize.toString(),
        'sources': sources,
      };

      final uri = Uri.parse('$_baseUrl/top-headlines').replace(
        queryParameters: queryParams,
      );

      logger.i('Fetching news from Urdu sources: ${uri.toString()}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;

        final newsList = articles.map((article) {
          return NewsModel(
            id: article['url'] ?? '',
            title: article['title'] ?? '',
            description: article['description'] ?? '',
            content: article['content'] ?? '',
            url: article['url'] ?? '',
            imageUrl: article['urlToImage'] ?? '',
            source: article['source']['name'] ?? '',
            publishedAt: DateTime.parse(
                article['publishedAt'] ?? DateTime.now().toIso8601String()),
            language: 'ur',
          );
        }).toList();

        // If no articles found from API, generate mock data
        if (newsList.isEmpty) {
          logger.i('No Urdu articles found from API, using mock data');
          return generateMockUrduNews(category);
        }

        return newsList;
      } else {
        logger.e('Error fetching from Urdu sources: ${response.body}');
        // Return mock data if API fails
        logger.i('Using mock Urdu news data due to API error');
        return generateMockUrduNews(category);
      }
    } catch (e) {
      logger.e('Exception in _fetchFromUrduSources: $e');
      // Return mock data on exception
      logger.i('Using mock Urdu news data due to exception');
      return generateMockUrduNews(category);
    }
  }

  /// Generates mock Urdu news for testing and fallback
  List<NewsModel> generateMockUrduNews(String? category) {
    logger.i('Generating mock Urdu news for category: ${category ?? "All"}');

    final DateTime now = DateTime.now();

    // Base mock news list with pure Urdu content (no transliteration mixed in)
    final List<Map<String, dynamic>> mockNews = [
      {
        'title': 'ایران اور عالمی طاقتوں کے درمیان نووی وارتا ناکامی سے دوچار',
        'transliteration':
            'Iran aur Aalmi Taqaton ke Darmiyan Novi Warta Nakami se Dochar',
        'description': 'ویانا میں جامع مذاکرات کے بعد کوئی پیش رفت نہیں ہوئی',
        'description_transliteration':
            'Vienna mein Jamey Muzakrat ke bad koi pesh raft nahi hui',
        'content':
            'ایران اور عالمی طاقتوں کے درمیان جوہری معاہدے پر مذاکرات کے تازہ ترین دور میں کوئی خاص پیش رفت نہیں ہوئی۔ مغربی ممالک ایران سے مزید شفافیت اور پابندیوں کی نگرانی کا مطالبہ کر رہے ہیں جبکہ ایران پابندیوں میں نرمی کا خواہاں ہے۔',
        'content_transliteration':
            'Iran aur aalmi taqaton ke darmiyan johri muahede par muzakrat ke taza tareen dour mein koi khas pesh raft nahi hui. Magribi mumalik Iran se mazeed shafafiyat aur pabandiyon ki nigrani ka mutalba kar rahe hain jabke Iran pabandiyon mein narmi ka khwahan hai.',
        'url': 'https://example.com/urdu/iran-nuclear-talks',
        'imageUrl':
            'https://images.unsplash.com/photo-1529244927325-b3ef2247b1f8',
        'source': 'اردو نیوز',
        'categories': ['General'],
        'publishedAt': now.subtract(const Duration(hours: 2)),
      },
      {
        'title': 'پاکستانی کرکٹ ٹیم کی شاندار کامیابی، سیریز میں تاریخی فتح',
        'transliteration':
            'Pakistani Cricket Team ki Shandar Kamyabi, Series mein Tareekhi Fateh',
        'description':
            'پاکستانی کرکٹ ٹیم نے سیریز میں فتح حاصل کر کے نیا ریکارڈ قائم کیا',
        'description_transliteration':
            'Pakistani cricket team ne series mein fateh hasil kar ke naya record qaim kia',
        'content':
            'پاکستانی کرکٹ ٹیم نے آخری میچ میں شاندار کارکردگی دکھاتے ہوئے حریف ٹیم کو شکست دے کر سیریز اپنے نام کر لی ہے۔ بابر اعظم کی قیادت میں ٹیم نے بیٹنگ اور باؤلنگ دونوں شعبوں میں اعلیٰ کھیل کا مظاہرہ کیا۔',
        'content_transliteration':
            'Pakistani cricket team ne aakhri match mein shandar karkardagi dikhate hue hareef team ko shikast de kar series apne naam kar li hai. Babar Azam ki qiadat mein team ne batting aur bowling donon shubon mein aala khel ka muzahira kia.',
        'url': 'https://example.com/urdu/cricket-victory-2023',
        'imageUrl':
            'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e',
        'source': 'کھیل نیوز',
        'categories': ['Sports'],
        'publishedAt': now.subtract(const Duration(hours: 5)),
      },
      {
        'title': 'پاکستانی فلم "خیال" کو بین الاقوامی فلم فیسٹیول میں اعزاز',
        'transliteration':
            'Pakistani Film "Khayal" ko Bainalaqwami Film Festival mein Aizaz',
        'description':
            'پاکستانی سینما کی نئی کامیابی، بین الاقوامی سطح پر اعتراف',
        'description_transliteration':
            'Pakistani cinema ki nayi kamyabi, bainalaqwami satah par aitaraf',
        'content':
            'پاکستانی فلم "خیال" نے مشہور بین الاقوامی فلم فیسٹیول میں بہترین فلم کا ایوارڈ جیت لیا ہے۔ فلم کی ہدایتکاری اور اداکاری کو خصوصی طور پر سراہا گیا۔ یہ پاکستانی سینما کے لیے ایک اہم کامیابی ہے جس سے عالمی سطح پر پاکستانی فنون کی شناخت بڑھی ہے۔',
        'content_transliteration':
            'Pakistani film "Khayal" ne mashhoor bainalaqwami film festival mein behtareen film ka award jeet liya hai. Film ki hidayatkari aur adakari ko khusoosi taur par saraha gaya. Yeh Pakistani cinema ke liye aik aham kamyabi hai jis se aalmi satah par Pakistani funoon ki shanakht barhi hai.',
        'url': 'https://example.com/urdu/film-award-2023',
        'imageUrl':
            'https://images.unsplash.com/photo-1536440136628-849c177e76a1',
        'source': 'فن و ثقافت',
        'categories': ['Entertainment'],
        'publishedAt': now.subtract(const Duration(hours: 8)),
      },
      {
        'title': 'نئی تعلیمی پالیسی: ٹیکنالوجی پر توجہ، نصاب میں تبدیلی',
        'transliteration':
            'Nayi Taleemi Policy: Technology par Tawajjoh, Nisab mein Tabdeeli',
        'description':
            'حکومت نے نئی تعلیمی پالیسی کا اعلان کر دیا، طلبہ کی مہارتوں پر زور',
        'description_transliteration':
            'Hukumat ne nayi taleemi policy ka elaan kar diya, talaba ki maharton par zor',
        'content':
            'حکومت نے نئی تعلیمی پالیسی کا اعلان کیا ہے جس میں طلبہ کی عملی مہارتوں پر خصوصی توجہ دی گئی ہے۔ نئے نصاب میں سائنس، ٹیکنالوجی اور ڈیجیٹل لیٹریسی کو زیادہ اہمیت دی گئی ہے، تاکہ طلبہ عالمی سطح پر مقابلہ کر سکیں۔',
        'content_transliteration':
            'Hukumat ne nayi taleemi policy ka elaan kiya hai jis mein talaba ki amali maharton par khusoosi tawajjoh di gayi hai. Naye nisab mein science, technology aur digital literacy ko zyada ahmiyat di gayi hai, ta ke talaba aalmi satah par muqabla kar sakein.',
        'url': 'https://example.com/urdu/education-policy-2023',
        'imageUrl':
            'https://images.unsplash.com/photo-1580582932707-520aed937b7b',
        'source': 'تعلیم نیوز',
        'categories': ['General'],
        'publishedAt': now.subtract(const Duration(hours: 12)),
      },
      {
        'title': 'صحت کے شعبے میں نئی ترقی: روبوٹک سرجری کا کامیاب تجربہ',
        'transliteration':
            'Sehat ke Shobay mein Nayi Taraqqi: Robotic Surgery ka Kamyab Tajurba',
        'description': 'پاکستان میں پہلی مرتبہ روبوٹک سرجری کی سہولت متعارف',
        'description_transliteration':
            'Pakistan mein pehli martaba robotic surgery ki sahulat mutarif',
        'content':
            'پاکستان کے ایک بڑے ہسپتال میں روبوٹک سرجری کی سہولت متعارف کروا دی گئی ہے۔ اس جدید ٹیکنالوجی سے سرجری کے عمل میں زیادہ درستگی، کم وقت اور کم خطرات کے ساتھ مریضوں کا علاج ممکن ہو گا۔ اس اقدام سے ملک میں صحت کی سہولیات میں نمایاں بہتری آئے گی۔',
        'content_transliteration':
            'Pakistan ke aik bade hospital mein robotic surgery ki sahulat mutarif karwa di gayi hai. Is jadeed technology se surgery ke amal mein zyada durusti, kam waqt aur kam khatrat ke sath marizon ka ilaj mumkin ho ga. Is iqdam se mulk mein sehat ki saholiyat mein numayan behtari aye gi.',
        'url': 'https://example.com/urdu/health-robotic-surgery',
        'imageUrl': 'https://images.unsplash.com/photo-1551601651-bc60f254d532',
        'source': 'صحت نیوز',
        'categories': ['Health'],
        'publishedAt': now.subtract(const Duration(hours: 15)),
      },
      {
        'title': 'پاکستان میں 5جی ٹیکنالوجی کی تعارف، تیز ترین انٹرنیٹ',
        'transliteration':
            'Pakistan mein 5G Technology ki Taruf, Tez Tareen Internet',
        'description': 'بڑے شہروں میں 5جی خدمات کی فراہمی کا آغاز',
        'description_transliteration':
            'Bare shahron mein 5G khidmat ki farahmi ka aghaz',
        'content':
            'پاکستان میں 5جی ٹیکنالوجی کا آغاز کر دیا گیا ہے۔ پہلے مرحلے میں بڑے شہروں میں یہ خدمت دستیاب ہوگی۔ 5جی ٹیکنالوجی سے انٹرنیٹ کی رفتار کافی حد تک بڑھ جائے گی جس سے ڈیجیٹل کاموں میں آسانی ہو گی اور نئے کاروباری مواقع پیدا ہوں گے۔',
        'content_transliteration':
            'Pakistan mein 5G technology ka aghaz kar diya gaya hai. Pehlay marhale mein bare shahron mein yeh khidmat dastayab ho gi. 5G technology se internet ki raftar kafi had tak barh jaye gi jis se digital kamon mein asani ho gi aur naye karobari mawaqay paida hon ge.',
        'url': 'https://example.com/urdu/5g-technology-launch',
        'imageUrl': 'https://images.unsplash.com/photo-1544197150-b99a580bb7a8',
        'source': 'ٹیک نیوز',
        'categories': ['Technology'],
        'publishedAt': now.subtract(const Duration(hours: 18)),
      },
      {
        'title': 'معیشت میں بہتری کے آثار: برآمدات میں اضافہ',
        'transliteration': 'Maeeshat mein Behtari ke Asar: Baramdat mein Izafa',
        'description': 'برآمدات میں نمایاں اضافہ، غیر ملکی زرمبادلہ میں بہتری',
        'description_transliteration':
            'Baramdat mein numayan izafa, ghair mulki zar mubadla mein behtari',
        'content':
            'ملک کی معیشت میں بہتری کے آثار دکھائی دے رہے ہیں۔ برآمدات میں گذشتہ سال کے مقابلے میں 15 فیصد اضافہ ہوا ہے۔ ٹیکسٹائل، آئی ٹی خدمات اور کھانے پینے کی اشیا کی برآمد میں خصوصی اضافہ دیکھا گیا ہے۔ اس سے غیر ملکی زرمبادلہ کے ذخائر میں بھی اضافہ ہوا ہے۔',
        'content_transliteration':
            'Mulk ki maeeshat mein behtari ke asar dikhai de rahe hain. Baramdat mein guzashta sal ke muqablay mein 15 feesad izafa hua hai. Textile, IT khidmat aur khane peene ki ashya ki baramad mein khusoosi izafa dekha gaya hai. Is se ghair mulki zar mubadla ke zakhair mein bhi izafa hua hai.',
        'url': 'https://example.com/urdu/economy-exports-increase',
        'imageUrl':
            'https://images.unsplash.com/photo-1526304640581-d334cdbbf45e',
        'source': 'بزنس رپورٹر',
        'categories': ['Business'],
        'publishedAt': now.subtract(const Duration(hours: 20)),
      },
      {
        'title': 'سائنسدانوں نے نئی کائناتی تحقیق سے پردہ اٹھا دیا',
        'transliteration':
            'Scientists ne Nayi Kaynati Tehqeeq se Parda Utha Diya',
        'description': 'کائناتی تحقیق میں نیا موڑ، نئے سیاروں کی دریافت',
        'description_transliteration':
            'Kaynati tehqeeq mein naya mor, naye sayaron ki daryaft',
        'content':
            'پاکستانی اور بین الاقوامی سائنسدانوں کی ٹیم نے مشترکہ تحقیق میں ہمارے شمسی نظام سے باہر چند نئے سیاروں کی دریافت کی ہے۔ ان سیاروں کی سطح پر پانی کے آثار ملے ہیں جو حیات کی موجودگی کے امکانات کو جنم دیتے ہیں۔ یہ تحقیق کائناتی علوم میں ایک اہم پیش رفت ہے۔',
        'content_transliteration':
            'Pakistani aur bainalaqwami scientists ki team ne mushtarka tehqeeq mein hamare shamsi nizam se bahir chand naye sayaron ki daryaft ki hai. In sayaron ki satah par pani ke asar milay hain jo hayat ki maujoodgi ke imkanat ko janam dete hain. Yeh tehqeeq kaynati uloom mein aik aham pesh raft hai.',
        'url': 'https://example.com/urdu/space-research-discovery',
        'imageUrl':
            'https://images.unsplash.com/photo-1614730321146-b6fa6a46bcb4',
        'source': 'سائنس ڈائجسٹ',
        'categories': ['Science'],
        'publishedAt': now.subtract(const Duration(hours: 22)),
      },
    ];

    // Filter mock news based on the category if it's provided and not 'All' or null
    List<Map<String, dynamic>> filteredNews;
    if (category != null && category.toLowerCase() != 'all') {
      filteredNews = mockNews.where((article) {
        return article['categories'].contains(category);
      }).toList();

      // If no articles match the category, return all mock news
      if (filteredNews.isEmpty) {
        logger.w(
            'No mock articles found for category: $category, returning all mock news');
        filteredNews = mockNews;
      }
    } else {
      // Return all news for 'All' category or null
      filteredNews = mockNews;
    }

    // Convert mock news to NewsModel objects with today's dates
    return filteredNews.map((article) {
      final newsDate = article['publishedAt'] ??
          now.subtract(Duration(hours: filteredNews.indexOf(article) + 1));

      return NewsModel(
        id: article['url'],
        title: article['title'],
        description: article['description'],
        content: article['content'],
        url: article['url'],
        imageUrl: validateImageUrl(
            article['imageUrl'], article['categories'][0], 'MockUrduService'),
        source: article['source'],
        publishedAt: newsDate,
        language: 'ur',
        categories: List<String>.from(article['categories']),
        metadata: {
          'isMockData': true,
          'provider': 'MockNewsService',
          'disclaimer': 'This is sample content for demonstration purposes',
          'openableUrl': false,
          'transliteration': {
            'title':
                article['transliteration'] ?? 'Transliteration not available',
            'description': article['description_transliteration'] ??
                'Transliteration not available',
          }
        },
      );
    }).toList();
  }

  // Helper method to save a list of articles to Firestore
  Future<void> _saveArticlesToFirestore(List<NewsModel> articles) async {
    for (final article in articles) {
      try {
        // Check if article already exists
        final existingArticle = await getNewsById(article.firestoreId);
        if (existingArticle == null) {
          // Only save if it doesn't exist already
          await saveNews(article);
        }
      } catch (e) {
        // Log error but don't interrupt the process
        logger.e('Error saving article ${article.firestoreId}: $e');
      }
    }
  }

  // Save news to Firestore
  Future<void> saveNews(NewsModel news) async {
    try {
      logger.i('Saving news with ID: ${news.firestoreId}');
      await _firestore
          .collection('news')
          .doc(news.firestoreId)
          .set(news.toMap());
    } catch (e) {
      logger.e('Error saving news: $e');
      throw Exception('Failed to save news: $e');
    }
  }

  // Get news from Firestore
  Stream<List<NewsModel>> getNewsStream({
    String? category,
    String? language,
    int limit = 20,
  }) {
    try {
      Query query = _firestore
          .collection('news')
          .orderBy('publishedAt', descending: true)
          .limit(limit);

      // Only apply category filter if it's not 'All'
      if (category != null && category.toLowerCase() != 'all') {
        query = query.where('categories', arrayContains: category);
      }

      if (language != null) {
        query = query.where('language', isEqualTo: language);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => NewsModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      logger.e('Failed to get news stream: $e');
      throw Exception('Failed to get news stream: $e');
    }
  }

  // Update news emotions
  Future<void> updateNewsEmotions(
      String newsId, Map<String, int> emotions) async {
    try {
      // Sanitize the document ID by removing any invalid characters
      final sanitizedId = newsId.replaceAll('//', '_').replaceAll('/', '_');

      logger.i('Updating emotions for news ID: $sanitizedId');
      await _firestore.collection('news').doc(sanitizedId).update({
        'emotions': emotions,
      });
    } catch (e) {
      logger.e('Error updating emotions: $e');
      throw Exception('Failed to update news emotions: $e');
    }
  }

  // Get news by ID
  Future<NewsModel?> getNewsById(String newsId) async {
    try {
      // Sanitize the document ID
      final sanitizedId = newsId.replaceAll('//', '_').replaceAll('/', '_');

      logger.i('Getting news by ID: $sanitizedId');
      final doc = await _firestore.collection('news').doc(sanitizedId).get();
      if (doc.exists) {
        return NewsModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logger.e('Error getting news by ID: $e');
      throw Exception('Failed to get news by ID: $e');
    }
  }

  // Search news
  Future<List<NewsModel>> searchNews(String query) async {
    try {
      // Check if API key is available
      if (_apiKey.isEmpty) {
        throw Exception('NEWS_API_KEY not found in environment variables');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/everything').replace(
          queryParameters: {
            'apiKey': _apiKey,
            'q': query,
            'language': 'en',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;

        return articles.map((article) {
          return NewsModel(
            id: article['url'] ?? '',
            title: article['title'] ?? '',
            description: article['description'] ?? '',
            content: article['content'] ?? '',
            url: article['url'] ?? '',
            imageUrl: article['urlToImage'] ?? '',
            source: article['source']['name'] ?? '',
            publishedAt: DateTime.parse(
                article['publishedAt'] ?? DateTime.now().toIso8601String()),
            language: 'en',
          );
        }).toList();
      } else {
        logger.e('Error response: ${response.body}');
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Exception in searchNews: $e');
      throw Exception('Failed to search news: $e');
    }
  }

  // Fetch Urdu news from multiple real sources
  Future<List<NewsModel>> fetchRealUrduNews(String? category) async {
    logger.i('Fetching real Urdu news (redirecting to primary implementation)');
    return await _fetchUrduNews(category, 20, true);
  }

  // Fetch news from UrduPoint API specifically for Urdu content
  Future<List<NewsModel>> _fetchFromUrduPointApi(String? category) async {
    const baseUrl = 'https://www.urdupoint.com';
    final categoryPath = category != null && category.toLowerCase() != 'all'
        ? category.toLowerCase()
        : 'latest-news';
    final url = '$baseUrl/latest-news/$categoryPath';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Use UTF-8 decoding for proper character handling
        final String utfDecodedBody = utf8.decode(response.bodyBytes);
        return _extractNewsFromUrduPointHtml(
            utfDecodedBody, baseUrl, category ?? 'General');
      } else {
        _logger.e(
            'Failed to fetch news from UrduPoint API: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching news from UrduPoint API: ${e.toString()}');
      return [];
    }
  }

  List<NewsModel> _extractNewsFromUrduPointHtml(
      String htmlContent, String baseUrl, String category) {
    try {
      final document = html_parser.parse(htmlContent);
      final unescape = HtmlUnescape();
      final newsList = <NewsModel>[];

      // Get news containers - adjust selectors based on UrduPoint's actual HTML structure
      final newsElements = document.querySelectorAll('.postsLoop .postItem');

      for (var element in newsElements) {
        try {
          // Extract title
          final titleElement = element.querySelector('.postTitle a');
          if (titleElement == null) continue;

          final title = unescape.convert(titleElement.text.trim());

          // Extract link
          final link = titleElement.attributes['href'] ?? '';
          final fullLink = link.startsWith('http') ? link : '$baseUrl$link';

          // Extract image
          String imageUrl = '';
          final imageElement = element.querySelector('.postImg img');
          if (imageElement != null) {
            imageUrl = imageElement.attributes['src'] ?? '';
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
              imageUrl = imageUrl.startsWith('/')
                  ? '$baseUrl$imageUrl'
                  : '$baseUrl/$imageUrl';
            }
          }

          // Validate and get fallback if needed
          imageUrl =
              validateImageUrl(imageUrl, category.toLowerCase(), 'UrduPoint');

          // Extract description (if available)
          String description = '';
          final descElement = element.querySelector('.postDesc');
          if (descElement != null) {
            description = unescape.convert(descElement.text.trim());
          }

          // Extract published date (if available)
          DateTime publishedAt = DateTime.now();
          final dateElement = element.querySelector('.postDate');
          if (dateElement != null) {
            final dateStr = dateElement.text.trim();
            try {
              // Try to parse the date if in a recognizable format
              // This is a placeholder - adjust based on actual date format
              publishedAt = DateTime.parse(dateStr);
            } catch (e) {
              _logger.w('Could not parse date: $dateStr, using current time');
            }
          }

          newsList.add(
            NewsModel(
              id: 'urdupoint-${fullLink.hashCode}',
              title: title,
              description: description,
              content: description,
              url: fullLink,
              imageUrl: imageUrl,
              source: 'UrduPoint',
              publishedAt: publishedAt,
              language: 'ur',
              categories: [category.toLowerCase()],
              metadata: {
                'isRealNews': true,
                'provider': 'UrduPoint',
                'reliability': 'high',
                'isUrduVerified': true,
              },
            ),
          );
        } catch (e) {
          _logger.e('Error parsing individual news item: ${e.toString()}');
          continue;
        }
      }

      _logger.d(
          'Successfully extracted ${newsList.length} news items from UrduPoint');
      return newsList;
    } catch (e) {
      _logger.e('Error extracting news from UrduPoint HTML: ${e.toString()}');
      return [];
    }
  }

  // Fetch from NewsData.io API for Urdu
  Future<List<NewsModel>> _fetchFromNewsDataApi(String? category) async {
    try {
      // Get API key from environment variables
      String apiKey = dotenv.get('NEWSDATA_API_KEY', fallback: '');
      if (apiKey.isEmpty) {
        logger.w('No NEWSDATA_API_KEY found in environment variables');
        return [];
      }

      // Map our app categories to NewsData.io categories
      String? newsDataCategory;
      if (category != null && category.toLowerCase() != 'all') {
        switch (category.toLowerCase()) {
          case 'business':
            newsDataCategory = 'business';
            break;
          case 'entertainment':
            newsDataCategory = 'entertainment';
            break;
          case 'health':
            newsDataCategory = 'health';
            break;
          case 'science':
            newsDataCategory = 'science';
            break;
          case 'sports':
            newsDataCategory = 'sports';
            break;
          case 'technology':
            newsDataCategory = 'technology';
            break;
          case 'general':
            newsDataCategory =
                'top'; // Use 'top' as closest match for 'general'
            break;
          default:
            newsDataCategory = null;
        }
      }

      // Base URL for Urdu news from Pakistan
      Map<String, String> queryParams = {
        'apikey': apiKey,
        'language': 'ur', // Urdu language
        'country': 'pk', // Pakistan
      };

      // Add category if available
      if (newsDataCategory != null) {
        queryParams['category'] = newsDataCategory;
      }

      // Construct the URL
      final uri = Uri.https('newsdata.io', '/api/1/news', queryParams);

      logger.i(
          'Fetching news from NewsData.io API: ${uri.toString().replaceAll(apiKey, "[REDACTED]")}');
      final response = await http.get(uri);

      logger.i('NewsData.io API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Use UTF-8 decoding for the response body to properly handle Urdu characters
        final String utfDecodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(utfDecodedBody);

        // Log sample of properly decoded response for debugging
        logger.i(
            'NewsData.io API response sample: ${utfDecodedBody.substring(0, min(200, utfDecodedBody.length))}');

        final articles = data['results'] as List;

        if (articles.isEmpty) {
          logger.w('No articles found from NewsData.io API for Urdu');
          return [];
        }

        logger.i('Retrieved ${articles.length} articles from NewsData.io API');
        logger
            .i('First article title: ${articles.first['title'] ?? 'No title'}');

        List<NewsModel> newsList = [];

        for (var article in articles) {
          try {
            final title = article['title'] ?? 'No title available';
            final description = article['description'] ?? '';
            final content = article['content'] ?? '';
            final url = article['link'] ?? '';
            final imageUrl = validateImageUrl(article['image_url'],
                newsDataCategory ?? 'general', 'NewsData.io');
            final source = article['source_id'] ?? 'NewsData.io';

            // More rigorous check for Urdu content - check both title and description
            final bool isTitleUrdu = _containsUrduScript(title);
            final bool isDescriptionUrdu =
                description.isNotEmpty && _containsUrduScript(description);

            // Skip if neither title nor description is in Urdu
            if (!isTitleUrdu && !isDescriptionUrdu) {
              logger.w('Skipping non-Urdu article from NewsData.io: $title');
              continue;
            }

            // Parse date or use fallback
            DateTime publishedAt;
            try {
              publishedAt = article['pubDate'] != null
                  ? DateTime.parse(article['pubDate'])
                  : DateTime.now()
                      .subtract(Duration(minutes: newsList.length * 5));
            } catch (_) {
              publishedAt = DateTime.now()
                  .subtract(Duration(minutes: newsList.length * 5));
            }

            // Map to our app category system
            final String newsCategory = category ??
                (newsDataCategory != null
                    ? newsDataCategory[0].toUpperCase() +
                        newsDataCategory.substring(1)
                    : 'General');

            // Create news model
            final newsItem = NewsModel(
              id: url,
              title: title,
              description: description,
              content: content,
              url: url,
              imageUrl: imageUrl,
              source: source,
              publishedAt: publishedAt,
              language: 'ur',
              categories: [newsCategory],
              metadata: {
                'isRealNews': true,
                'provider': 'NewsData.io',
                'reliability': 'high',
                'isUrduVerified': true,
              },
            );

            newsList.add(newsItem);
          } catch (e) {
            logger.e('Error parsing NewsData.io article: $e');
            continue;
          }
        }

        if (newsList.isEmpty) {
          logger.w('No valid Urdu articles found in NewsData.io response');
        }

        return newsList;
      } else {
        logger.e(
            'Error fetching from NewsData.io API: ${response.statusCode}, ${response.body}');
        return [];
      }
    } catch (e) {
      logger.e('Exception in _fetchFromNewsDataApi: $e');
      return [];
    }
  }

  // Fetch news from GNews API for Urdu
  Future<List<NewsModel>> _fetchFromGNewsApi(String? category) async {
    try {
      // GNews API allows searching for Urdu news
      String apiKey = dotenv.get('GNEWS_API_KEY', fallback: '');
      if (apiKey.isEmpty) {
        logger.w('No GNEWS_API_KEY found in environment variables');
        return [];
      }

      // Map our app categories to GNews topics
      String? gNewsTopic;
      if (category != null && category.toLowerCase() != 'all') {
        // GNews topic mapping (lowercase): business, entertainment, health, science, sports, technology
        // Unsupported in GNews directly: general, but we can use 'world' or 'nation'
        switch (category.toLowerCase()) {
          case 'business':
            gNewsTopic = 'business';
            break;
          case 'entertainment':
            gNewsTopic = 'entertainment';
            break;
          case 'health':
            gNewsTopic = 'health';
            break;
          case 'science':
            gNewsTopic = 'science';
            break;
          case 'sports':
            gNewsTopic = 'sports';
            break;
          case 'technology':
            gNewsTopic = 'technology';
            break;
          case 'general':
            gNewsTopic = 'world'; // Use 'world' as closest match for 'general'
            break;
          default:
            gNewsTopic = null; // No matching topic
        }
      }

      // Base URL for Urdu news from Pakistan
      Map<String, String> queryParams = {
        'apikey': apiKey,
        'lang': 'ur', // Urdu language
        'country': 'pk', // Pakistan
        'max': '20', // Limit results
      };

      // Add topic if available
      if (gNewsTopic != null) {
        queryParams['topic'] = gNewsTopic;
      }

      // Construct the URL
      final uri = Uri.https('gnews.io', '/api/v4/top-headlines', queryParams);

      logger.i(
          'Fetching news from GNews API: ${uri.toString().replaceAll(apiKey, "[REDACTED]")}');
      final response = await http.get(uri);

      logger.i('GNews API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Use UTF-8 decoding to properly handle Urdu characters
        final String utfDecodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(utfDecodedBody);

        // Log sample of response for debugging in dev mode only
        logger.i(
            'GNews API response sample: ${utfDecodedBody.substring(0, min(200, utfDecodedBody.length))}');

        final articles = data['articles'] as List;
        final DateTime now = DateTime.now();

        if (articles.isEmpty) {
          logger.w('No articles found from GNews API for Urdu');
          return [];
        }

        logger.i('Retrieved ${articles.length} articles from GNews API');
        logger
            .i('First article title: ${articles.first['title'] ?? 'No title'}');

        List<NewsModel> newsList = [];

        for (var article in articles) {
          try {
            final title = article['title'] ?? 'No title available';
            final description = article['description'] ?? '';
            final content = article['content'] ?? '';
            final url = article['url'] ?? '';
            final imageUrl = validateImageUrl(
                article['image'], gNewsTopic ?? 'general', 'GNews');
            final source = article['source']?['name'] ?? 'GNews';
            final publishedAt = article['publishedAt'] != null
                ? DateTime.parse(article['publishedAt'])
                : now.subtract(Duration(minutes: newsList.length * 5));

            // More rigorous check for Urdu content - check both title and description
            final bool isTitleUrdu = _containsUrduScript(title);
            final bool isDescriptionUrdu =
                description.isNotEmpty && _containsUrduScript(description);

            // Skip if neither title nor description is in Urdu
            if (!isTitleUrdu && !isDescriptionUrdu) {
              logger.w('Skipping non-Urdu article from GNews: $title');
              continue;
            }

            // Map back to our app category system for consistency
            String newsCategory = 'General'; // Default
            if (gNewsTopic != null) {
              switch (gNewsTopic) {
                case 'world':
                  newsCategory = 'General';
                  break;
                default:
                  // Capitalize first letter for consistency with our category naming
                  newsCategory =
                      gNewsTopic[0].toUpperCase() + gNewsTopic.substring(1);
              }
            } else if (category != null && category.toLowerCase() != 'all') {
              // Use the original category if provided and not "All"
              newsCategory = category;
            }

            // Create news model
            final newsItem = NewsModel(
              id: url,
              title: title,
              description: description,
              content: content,
              url: url,
              imageUrl: imageUrl,
              source: source,
              publishedAt: publishedAt,
              language: 'ur',
              categories: [newsCategory],
              metadata: {
                'isRealNews': true,
                'provider': 'GNews',
                'reliability': 'high',
                'isUrduVerified': true,
              },
            );

            newsList.add(newsItem);
          } catch (e) {
            logger.e('Error parsing GNews article: $e');
            continue;
          }
        }

        return newsList;
      } else {
        logger.e(
            'Error fetching from GNews API: ${response.statusCode}, ${response.body}');
        return [];
      }
    } catch (e) {
      logger.e('Exception in _fetchFromGNewsApi: $e');
      return [];
    }
  }

  // Fetch news from GNews API for English
  Future<List<NewsModel>> _fetchFromGNewsApiForEnglish(String? category) async {
    try {
      // GNews API allows searching for English news
      String apiKey = dotenv.get('GNEWS_API_KEY', fallback: '');
      if (apiKey.isEmpty) {
        logger.w('No GNEWS_API_KEY found in environment variables');
        return [];
      }

      // Map our app categories to GNews topics
      String? gNewsTopic;
      if (category != null && category.toLowerCase() != 'all') {
        // GNews topic mapping (lowercase): business, entertainment, health, science, sports, technology
        // Unsupported in GNews directly: general, but we can use 'world' or 'nation'
        switch (category.toLowerCase()) {
          case 'business':
            gNewsTopic = 'business';
            break;
          case 'entertainment':
            gNewsTopic = 'entertainment';
            break;
          case 'health':
            gNewsTopic = 'health';
            break;
          case 'science':
            gNewsTopic = 'science';
            break;
          case 'sports':
            gNewsTopic = 'sports';
            break;
          case 'technology':
            gNewsTopic = 'technology';
            break;
          case 'general':
            gNewsTopic = 'world'; // Use 'world' as closest match for 'general'
            break;
          default:
            gNewsTopic = null; // No matching topic
        }
      }

      // Base URL for English news
      Map<String, String> queryParams = {
        'apikey': apiKey,
        'lang': 'en', // English language
        'max': '20', // Limit results
        'expand': 'content', // Request full content when available
      };

      // Add topic if available
      if (gNewsTopic != null) {
        queryParams['topic'] = gNewsTopic;
      }

      // Construct the URL
      final uri = Uri.https('gnews.io', '/api/v4/top-headlines', queryParams);

      logger.i(
          'Fetching English news from GNews API: ${uri.toString().replaceAll(apiKey, "[REDACTED]")}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Use UTF-8 decoding for proper character handling
        final String utfDecodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(utfDecodedBody);
        final articles = data['articles'] as List;
        final DateTime now = DateTime.now();

        if (articles.isEmpty) {
          logger.w('No English articles found from GNews API');
          return [];
        }

        logger
            .i('Retrieved ${articles.length} English articles from GNews API');

        List<NewsModel> newsList = [];

        for (var article in articles) {
          try {
            final title = article['title'] ?? 'No title available';
            final description = article['description'] ?? '';
            String content = article['content'] ?? '';
            final url = article['url'] ?? '';
            final imageUrl = validateImageUrl(
                article['image'], gNewsTopic ?? 'general', 'GNews');
            final source = article['source']?['name'] ?? 'GNews';
            final publishedAt = article['publishedAt'] != null
                ? DateTime.parse(article['publishedAt'])
                : now.subtract(Duration(minutes: newsList.length * 5));

            // Validate URL for opening
            final bool hasValidUrl =
                url.isNotEmpty && Uri.tryParse(url)?.hasScheme == true;
            if (!hasValidUrl) {
              logger.w('Skipping article with invalid URL: $url');
              continue;
            }

            // Ensure we have sufficient content
            if (content.length < 100 && description.isNotEmpty) {
              content = description + '\n\n' + content;
            }

            // Map back to our app category system for consistency
            String newsCategory = 'General'; // Default
            if (gNewsTopic != null) {
              switch (gNewsTopic) {
                case 'world':
                  newsCategory = 'General';
                  break;
                default:
                  // Capitalize first letter for consistency with our category naming
                  newsCategory =
                      gNewsTopic[0].toUpperCase() + gNewsTopic.substring(1);
              }
            } else if (category != null && category.toLowerCase() != 'all') {
              // Use the original category if provided and not "All"
              newsCategory = category;
            }

            // Create news model with full article content data
            final newsItem = NewsModel(
              id: url,
              title: title,
              description: description,
              content: content,
              url: url, // This is the original source URL that users can open
              imageUrl: imageUrl,
              source: source,
              publishedAt: publishedAt,
              language: 'en',
              categories: [newsCategory],
              // Adding metadata to indicate this is from a reliable source
              metadata: {
                'isRealNews': true,
                'provider': 'GNews',
                'reliability': 'high',
                'openableUrl': true,
              },
            );

            newsList.add(newsItem);
          } catch (e) {
            logger.e('Error parsing GNews English article: $e');
            continue;
          }
        }

        return newsList;
      } else {
        logger.e(
            'Error fetching English news from GNews API: ${response.statusCode}, ${response.body}');
        return [];
      }
    } catch (e) {
      logger.e('Exception in _fetchFromGNewsApiForEnglish: $e');
      return [];
    }
  }

  // Fetch from NewsData.io API for English
  Future<List<NewsModel>> _fetchFromNewsDataApiForEnglish(
      String? category) async {
    try {
      // Get API key from environment variables
      String apiKey = dotenv.get('NEWSDATA_API_KEY', fallback: '');
      if (apiKey.isEmpty) {
        logger.w('No NEWSDATA_API_KEY found in environment variables');
        return [];
      }

      // Map our app categories to NewsData.io categories
      String? newsDataCategory;
      if (category != null && category.toLowerCase() != 'all') {
        switch (category.toLowerCase()) {
          case 'business':
            newsDataCategory = 'business';
            break;
          case 'entertainment':
            newsDataCategory = 'entertainment';
            break;
          case 'health':
            newsDataCategory = 'health';
            break;
          case 'science':
            newsDataCategory = 'science';
            break;
          case 'sports':
            newsDataCategory = 'sports';
            break;
          case 'technology':
            newsDataCategory = 'technology';
            break;
          case 'general':
            newsDataCategory =
                'top'; // Use 'top' as closest match for 'general'
            break;
          default:
            newsDataCategory = null;
        }
      }

      // Base URL for English news
      Map<String, String> queryParams = {
        'apikey': apiKey,
        'language': 'en', // English language
        'country': 'us,gb', // US and UK sources
      };

      // Add category if available
      if (newsDataCategory != null) {
        queryParams['category'] = newsDataCategory;
      }

      // Construct the URL
      final uri = Uri.https('newsdata.io', '/api/1/news', queryParams);

      logger.i(
          'Fetching news from NewsData.io API for English: ${uri.toString()}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Use UTF-8 decoding to ensure proper character handling
        final String utfDecodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(utfDecodedBody);
        final articles = data['results'] as List;

        if (articles.isEmpty) {
          logger.w('No articles found from NewsData.io API');
          return [];
        }

        logger.i('Retrieved ${articles.length} articles from NewsData.io API');

        List<NewsModel> newsList = [];
        final DateTime now = DateTime.now();

        for (var article in articles) {
          try {
            final title = article['title'] ?? 'No title available';
            final description = article['description'] ?? '';
            final content = article['content'] ?? '';
            final url = article['link'] ?? '';
            final imageUrl = validateImageUrl(article['image_url'],
                newsDataCategory ?? 'general', 'NewsData.io');
            final source = article['source_id'] ?? 'NewsData.io';

            // Parse date or use fallback
            DateTime publishedAt;
            try {
              publishedAt = article['pubDate'] != null
                  ? DateTime.parse(article['pubDate'])
                  : now.subtract(Duration(minutes: newsList.length * 5));
            } catch (_) {
              publishedAt =
                  now.subtract(Duration(minutes: newsList.length * 5));
            }

            // Map to our app category system
            final String newsCategory = category ??
                (newsDataCategory != null
                    ? newsDataCategory[0].toUpperCase() +
                        newsDataCategory.substring(1)
                    : 'General');

            // Create news model
            final newsItem = NewsModel(
              id: url,
              title: title,
              description: description,
              content: content,
              url: url, // Original source URL
              imageUrl: imageUrl,
              source: source,
              publishedAt: publishedAt,
              language: 'en',
              categories: [newsCategory],
              metadata: {
                'isRealNews': true,
                'provider': 'NewsData.io',
                'reliability': 'high'
              },
            );

            newsList.add(newsItem);
          } catch (e) {
            logger.e('Error parsing NewsData.io article for English: $e');
            continue;
          }
        }

        return newsList;
      } else {
        logger.e(
            'Error fetching from NewsData.io API: ${response.statusCode}, ${response.body}');
        return [];
      }
    } catch (e) {
      logger.e('Exception in _fetchFromNewsDataApiForEnglish: $e');
      return [];
    }
  }

  // Fetch from NewsAPI for English
  Future<List<NewsModel>> _fetchFromNewsAPIForEnglish(String? category) async {
    try {
      if (_apiKey.isEmpty) {
        logger.w('NewsAPI key is empty, skipping NewsAPI attempt');
        return [];
      }

      final queryParams = {
        'apiKey': _apiKey,
        'pageSize': '20',
        'language': 'en',
      };

      if (category != null && category.toLowerCase() != 'all') {
        queryParams['category'] = category.toLowerCase();
      }

      final uri = Uri.parse('$_baseUrl/top-headlines').replace(
        queryParameters: queryParams,
      );

      logger.i(
          'Fetching news from NewsAPI: ${uri.toString().replaceAll(_apiKey, "[REDACTED]")}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Use UTF-8 decoding for proper character handling
        final String utfDecodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(utfDecodedBody);
        final articles = data['articles'] as List;

        if (articles.isEmpty) {
          logger.w('No articles found from NewsAPI');
          return [];
        }

        logger.i('Retrieved ${articles.length} English articles from NewsAPI');
        final List<NewsModel> newsList = [];

        for (var article in articles) {
          try {
            final title = article['title'] ?? '';
            final description = article['description'] ?? '';
            String content = article['content'] ?? '';
            final url = article['url'] ?? '';
            final imageUrl = validateImageUrl(
                article['urlToImage'], category ?? 'general', 'NewsAPI');
            final source = article['source']['name'] ?? '';
            final publishedAt = article['publishedAt'] != null
                ? DateTime.parse(article['publishedAt'])
                : DateTime.now()
                    .subtract(Duration(minutes: newsList.length * 5));

            // Skip articles with invalid or empty titles/URLs
            if (title.isEmpty || url.isEmpty) {
              logger
                  .w('Skipping article with empty title or URL: $title, $url');
              continue;
            }

            // Validate URL for opening
            final bool hasValidUrl =
                url.isNotEmpty && Uri.tryParse(url)?.hasScheme == true;
            if (!hasValidUrl) {
              logger.w('Skipping article with invalid URL: $url');
              continue;
            }

            // Ensure we have sufficient content
            if (content.length < 100 && description.isNotEmpty) {
              content = description + '\n\n' + content;
            }

            final newsItem = NewsModel(
              id: url,
              title: title,
              description: description,
              content: content,
              url: url,
              imageUrl: imageUrl,
              source: source,
              publishedAt: publishedAt,
              language: 'en',
              categories: [category ?? 'General'],
              metadata: {
                'isRealNews': true,
                'provider': 'NewsAPI',
                'reliability': 'high',
                'openableUrl': true,
              },
            );

            newsList.add(newsItem);
          } catch (e) {
            logger.e('Error parsing NewsAPI article: $e');
            continue;
          }
        }

        return newsList;
      } else {
        logger.e(
            'Error response from NewsAPI: ${response.statusCode}, ${response.body}');
        return [];
      }
    } catch (e) {
      logger.e('Exception using NewsAPI: $e');
      return [];
    }
  }

  // Helper method to check if text contains Urdu script or is relevant to Pakistan content
  bool _containsUrduScript(String text) {
    if (text.isEmpty) return false;

    // For debugging only - convert to lowercase for case-insensitive matching
    final lowerText = text.toLowerCase();

    // Extended Urdu/Arabic Unicode ranges for actual Urdu text
    final RegExp urduRegex =
        RegExp(r'[\u0600-\u06FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    final bool containsUrduChars = urduRegex.hasMatch(text);

    // Count how many Urdu characters are in the text
    int urduCharCount = 0;
    for (int i = 0; i < text.length; i++) {
      if (urduRegex.hasMatch(text[i])) {
        urduCharCount++;
      }
    }

    // Calculate percentage of Urdu characters in text
    double urduPercentage = text.isNotEmpty ? urduCharCount / text.length : 0;

    // Criteria for qualifying as Urdu content:
    // 1. Must contain some Urdu script characters
    // 2. At least 15% of characters should be Urdu script OR
    // 3. Should have Pakistan-related keywords AND some Urdu characters

    // Check for Pakistan-related keywords
    final bool containsPakistanKeywords = lowerText.contains('pakistan') ||
        lowerText.contains('urdu') ||
        lowerText.contains('islamabad') ||
        lowerText.contains('lahore') ||
        lowerText.contains('karachi') ||
        lowerText.contains('pakistani');

    // Determine if this is real Urdu content
    final bool isUrduContent = containsUrduChars &&
        (urduPercentage >= 0.15 || // At least 15% Urdu characters
            (containsPakistanKeywords &&
                urduCharCount > 5) // Or Pakistan content with some Urdu
        );

    logger.i(
        'Urdu content analysis - Contains Urdu chars: $containsUrduChars, Urdu percentage: ${(urduPercentage * 100).toStringAsFixed(1)}%, Pakistan keywords: $containsPakistanKeywords, Is Urdu: $isUrduContent, Sample: "${text.substring(0, min(30, text.length))}..."');

    return isUrduContent;
  }

  // Helper method to validate and provide fallback image URLs if needed
  String validateImageUrl(String? imageUrl, String category, String source) {
    // Check if the image URL is valid
    if (imageUrl == null || imageUrl.isEmpty) {
      return _getFallbackImageUrl(category);
    }

    // Validate URL format
    try {
      final uri = Uri.parse(imageUrl);
      if (!uri.hasScheme ||
          (!uri.scheme.startsWith('http') && !uri.scheme.startsWith('https'))) {
        logger.w('Invalid image URL scheme: $imageUrl');
        return _getFallbackImageUrl(category);
      }

      // Check common image extensions (not perfect but helpful)
      final lowerUrl = imageUrl.toLowerCase();
      if (!lowerUrl.endsWith('.jpg') &&
          !lowerUrl.endsWith('.jpeg') &&
          !lowerUrl.endsWith('.png') &&
          !lowerUrl.endsWith('.gif') &&
          !lowerUrl.endsWith('.webp') &&
          !lowerUrl.contains('image')) {
        // URL doesn't have obvious image extension but might still be valid
        // Log it but still return the URL
        logger.i('Image URL without obvious image extension: $imageUrl');
      }

      return imageUrl;
    } catch (e) {
      logger.w('Failed to parse image URL: $imageUrl, error: $e');
      return _getFallbackImageUrl(category);
    }
  }

  // Get fallback image URL based on category
  String _getFallbackImageUrl(String category) {
    // Category-specific fallback images from Unsplash
    switch (category.toLowerCase()) {
      case 'business':
        return 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800&q=80';
      case 'entertainment':
        return 'https://images.unsplash.com/photo-1586899028174-e7098604235b?w=800&q=80';
      case 'health':
        return 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=800&q=80';
      case 'science':
        return 'https://images.unsplash.com/photo-1507413245164-6160d8298b31?w=800&q=80';
      case 'sports':
        return 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=800&q=80';
      case 'technology':
        return 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80';
      default: // General
        return 'https://images.unsplash.com/photo-1495020689067-958852a7765e?w=800&q=80';
    }
  }
}
