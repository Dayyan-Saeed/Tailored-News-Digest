import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/logger.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        // Configure all web settings
        ..enableZoom(true)
        ..setBackgroundColor(Colors.white)
        // Apply user agent
        ..setUserAgent(
            "Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36")
        // Configure navigation
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              logger.i('WebView: Page started loading: $url');
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            },
            onPageFinished: (String url) {
              logger.i('WebView: Page finished loading: $url');
              setState(() {
                _isLoading = false;
              });

              // Fix viewport and ensure proper content display
              _controller.runJavaScript('''
                // Function to optimize content display
                function optimizeContent() {
                  // 1. Set proper viewport
                  var viewport = document.querySelector('meta[name="viewport"]');
                  if (!viewport) {
                    viewport = document.createElement('meta');
                    viewport.name = 'viewport';
                    document.head.appendChild(viewport);
                  }
                  viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=2.0, user-scalable=yes';
                  
                  // 2. Handle RTL languages (for Urdu/Arabic content)
                  var hasRTLText = /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]/.test(document.body.innerText);
                  if (hasRTLText || document.documentElement.dir === 'rtl') {
                    document.documentElement.dir = 'rtl';
                    document.body.dir = 'rtl';
                  }
                  
                  // 3. General display improvements
                  var style = document.createElement('style');
                  style.textContent = `
                    body {
                      -webkit-text-size-adjust: 100%;
                      text-size-adjust: 100%;
                      overflow-x: hidden !important;
                      width: 100% !important;
                    }
                    img, video, iframe {
                      max-width: 100%;
                      height: auto;
                    }
                  `;
                  document.head.appendChild(style);
                }
                
                // Execute the optimization
                optimizeContent();
                
                // Also apply after a delay for dynamic content
                setTimeout(optimizeContent, 1000);
              ''');
            },
            onWebResourceError: (WebResourceError error) {
              logger.e('WebView error: ${error.description}');
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = error.description;
              });
            },
          ),
        )
        // Load the URL after configuration
        ..loadRequest(Uri.parse(widget.url));
    } catch (e) {
      logger.e('Error initializing WebView: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open in external browser',
            onPressed: () {
              Navigator.of(context).pop(true); // Return true to open externally
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_hasError)
            Transform.rotate(
              angle: 3.14159, // pi radians = 180 degrees
              child: WebViewWidget(controller: _controller),
            ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load the article',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    onPressed: () {
                      _initWebView();
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Try External Browser'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
