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

1. Clone the repository
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Set up Firebase:
   - Create a new Firebase project
   - Add Android and iOS apps
   - Download and add configuration files
   - Enable Authentication and Firestore

4. Set up News API:
   - Get an API key from [NewsAPI](https://newsapi.org)
   - Add the API key to your environment variables

5. Run the app:
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
