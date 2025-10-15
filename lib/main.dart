import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/statistics_screen.dart';
import 'widgets/navigation/main_navigation.dart';
import 'utils/logger.dart';
import 'utils/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    logger.i("Loading environment variables...");
    await dotenv.load(fileName: ".env");
    logger.i("Environment variables loaded successfully");

    logger.i("Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i("Firebase initialized successfully");
  } catch (e) {
    logger.e("Error during initialization", e);
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?._locale.value = newLocale;
  }

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<Locale?> _locale = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    logger.d("Building MyApp...");
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) {
            logger.d("Creating AuthService...");
            return AuthService();
          },
        ),
        Provider<ApiService>(
          create: (_) {
            logger.d("Creating ApiService...");
            return ApiService();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            logger.d("Creating ThemeProvider...");
            return ThemeProvider();
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Determine text direction based on selected language
          final textDirection = themeProvider.language == 'ur'
              ? TextDirection.rtl
              : TextDirection.ltr;

          return Directionality(
            textDirection: textDirection,
            child: ValueListenableBuilder<Locale?>(
              valueListenable: _locale,
              builder: (context, locale, child) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Tailored News Digest',
                  theme: themeProvider.themeData,
                  locale: locale,
                  supportedLocales: const [
                    Locale('en'), // English
                    Locale('ur'), // Urdu
                  ],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  localeResolutionCallback: (locale, supportedLocales) {
                    for (var supportedLocale in supportedLocales) {
                      if (supportedLocale.languageCode == locale?.languageCode) {
                        return supportedLocale;
                      }
                    }
                    // If the locale of the device is not supported, use the first one
                    // from the list (English, in this case).
                    return supportedLocales.first;
                  },
                  initialRoute: '/',
                  routes: {
                    '/': (context) => const AuthWrapper(),
                    '/login': (context) => const LoginScreen(),
                    '/register': (context) => const RegisterScreen(),
                    '/home': (context) => const MainNavigation(),
                    '/profile': (context) => const ProfileScreen(),
                    '/recommendations': (context) => const RecommendationsScreen(),
                    '/settings': (context) => const SettingsScreen(),
                    '/statistics': (context) => const StatisticsScreen(),
                    '/subscription': (context) => const SubscriptionScreen(),
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    logger.d("Building AuthWrapper...");
    return StreamBuilder<UserModel?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        logger.d(
            "StreamBuilder update: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}");
        if (snapshot.hasError) {
          logger.e("StreamBuilder error", snapshot.error);
          return Scaffold(
            body: Center(
              child: Text("Error: ${snapshot.error}"),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          logger.d("Showing loading indicator...");
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          logger.i("User is signed in, navigating to MainNavigation");
          return const MainNavigation();
        }

        logger.i("User is not signed in, navigating to LoginScreen");
        return const LoginScreen();
      },
    );
  }
}

class SummaryTestScreen extends StatefulWidget {
  const SummaryTestScreen({super.key});

  @override
  SummaryTestScreenState createState() => SummaryTestScreenState();
}

class SummaryTestScreenState extends State<SummaryTestScreen> {
  final TextEditingController _contentController = TextEditingController();
  String _language = 'en';
  String _result = '';
  bool _loading = false;

  Future<void> _fetchSummary() async {
    setState(() {
      _loading = true;
      _result = '';
    });
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final summary = await apiService.getSummary(
        _contentController.text,
        language: _language,
      );
      if (kDebugMode) {
        if (kDebugMode) {
          print('Summary response: $summary');
        }
      }
      setState(() {
        _result = summary['summary'] ?? summary['error'] ?? summary.toString();
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
      appBar: AppBar(title: const Text('Test Summary API')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Article Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _language,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ur', child: Text('Urdu')),
              ],
              onChanged: (val) => setState(() => _language = val!),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _fetchSummary,
              child: _loading ? const CircularProgressIndicator() : const Text('Fetch Summary'),
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

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: const Center(child: Text('Subscription Page Placeholder')),
    );
  }
}
