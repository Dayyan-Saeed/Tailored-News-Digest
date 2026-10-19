# Tailored News Digest

A personalized news aggregation app that delivers news summaries based on user preferences, emotional responses, and engagement levels.

## Features

- 📰 Personalized News Feed
- 😊 Emotion-based Recommendations
- 🌐 Multi-language Summarization
- 🎯 Points-Based Access System
- 👥 Community Interaction
- ♿ Accessibility Features
- 📚 Educational Add-on

## Project Structure

```
lib/
├── main.dart
├── config/
│   ├── theme.dart
│   └── routes.dart
├── models/
│   ├── user_model.dart
│   ├── news_model.dart
│   └── emotion_model.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── news/
│   │   ├── news_feed_screen.dart
│   │   └── news_detail_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   └── onboarding/
│       └── onboarding_screen.dart
├── services/
│   ├── auth_service.dart
│   ├── news_service.dart
│   ├── emotion_service.dart
│   └── storage_service.dart
├── widgets/
│   ├── common/
│   │   ├── custom_button.dart
│   │   └── custom_text_field.dart
│   └── news/
│       ├── news_card.dart
│       └── emotion_selector.dart
└── utils/
    ├── constants.dart
    └── helpers.dart
```

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone <your-repository-url>
   cd tailored_news_digest
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Set up Firebase:
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Add Android and iOS apps to your Firebase project
   - Download `google-services.json` for Android and place it in `android/app/`
   - Download `GoogleService-Info.plist` for iOS and place it in `ios/Runner/`
   - **IMPORTANT**: These files are excluded from git for security. Each developer needs their own copies.
   - Enable Authentication and Firestore in your Firebase Console
   - Run `flutterfire configure` to generate `firebase_options.dart`

4. Set up News API:
   - Get an API key from [NewsAPI](https://newsapi.org) or [GNews](https://gnews.io)
   - Update `lib/config/api_config.dart` with your API key

5. Backend Setup (optional):
   - Navigate to `tailored_news_backend/`
   - Create a Python virtual environment: `python -m venv venv`
   - Activate it: `venv\Scripts\activate` (Windows) or `source venv/bin/activate` (Mac/Linux)
   - Install dependencies: `pip install -r requirements.txt` (if exists)
   - Run migrations: `python manage.py migrate`
   - Start the server: `python manage.py runserver`

6. Run the app:
   ```bash
   flutter run
   ```

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```
NEWS_API_KEY=your_news_api_key
FIREBASE_API_KEY=your_firebase_api_key
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

# End
