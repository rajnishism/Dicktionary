# 📚 Dicktionary - Vocabulary Memory App

A Flutter-based mobile application that helps users retain English word meanings through personalized tracking and periodic reinforcement notifications.

## Features

### Core Functionality
- **Word Search**: Look up English word definitions using a free dictionary API
- **Smart Tracking**: Automatically tracks search frequency and recency for each word
- **Priority Scoring**: Words are ranked using a sophisticated algorithm:
  ```
  priority_score = (search_count × 0.7) + (recency_score × 0.3)
  recency_score = 1 / (days_since_last_search + 1)
  ```
- **History View**: Browse all searched words sorted by priority score
- **Reinforcement Notifications**: Periodic notifications show word meanings to reinforce memory

### Technical Highlights
- ✅ 100% local storage (no backend required)
- ✅ SQLite database for persistent data
- ✅ Background task scheduling with WorkManager
- ✅ Modern Material Design 3 UI
- ✅ Cross-platform (iOS & Android)

## UI Prototype

### Search Screen
The main screen features a clean gradient background with a prominent search box. Users can enter any English word to look up its definition.

![Search Screen](/.gemini/antigravity/brain/572a5420-bbc8-49a3-aef4-9ae8ba805506/search_screen_mockup_1771152650971.png)

### Word Result Display
When a word is found, it's displayed in a beautiful card with the definition and a confirmation that it's been saved to your vocabulary.

![Word Result](/.gemini/antigravity/brain/572a5420-bbc8-49a3-aef4-9ae8ba805506/word_result_mockup_1771152666791.png)

### History Screen
View all your searched words sorted by priority score. Each card shows the word, meaning, search count, and when you last looked it up.

![History Screen](/.gemini/antigravity/brain/572a5420-bbc8-49a3-aef4-9ae8ba805506/history_screen_mockup_1771152688821.png)


## Setup Instructions

### Prerequisites
- Flutter SDK (3.11.0 or higher)
- Android Studio / Xcode for mobile development
- A physical device or emulator

### Installation

1. **Clone or navigate to the project directory**
   ```bash
   cd /Users/rajnish/Desktop/Personal\ /CHODING/Dictionary
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For Android
   flutter run

   # For iOS
   flutter run -d ios
   ```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── word_memory.dart         # Word data model
├── services/
│   ├── dictionary_api.dart      # Dictionary API integration
│   ├── database_service.dart    # SQLite operations
│   ├── priority_engine.dart     # Priority scoring logic
│   └── notification_service.dart # Notifications & background tasks
├── screens/
│   ├── search_screen.dart       # Word search UI
│   └── history_screen.dart      # Word history UI
└── widgets/
    └── word_card.dart           # Reusable word display component
```

## How It Works

### 1. Search Flow
1. User enters a word in the search box
2. App fetches definition from `https://api.dictionaryapi.dev`
3. Word and meaning are saved to local SQLite database
4. If word already exists, search count increments and timestamp updates

### 2. Priority System
Words with higher priority scores appear first in history:
- **Frequently searched words** get higher scores (70% weight)
- **Recently searched words** stay in rotation (30% weight)
- This ensures important words are reinforced more often

### 3. Notifications
- Background task runs every hour
- Fetches the highest priority word
- Displays notification with word and meaning
- Works even when app is closed

## API Information

**Dictionary API**: [Free Dictionary API](https://dictionaryapi.dev/)
- Endpoint: `https://api.dictionaryapi.dev/api/v2/entries/en/<word>`
- No authentication required
- Returns comprehensive word information including definitions, phonetics, and examples

## Dependencies

```yaml
sqflite: ^2.3.0                          # Local database
path_provider: ^2.1.1                    # File system paths
http: ^1.1.0                             # HTTP requests
flutter_local_notifications: ^16.3.0     # Local notifications
workmanager: ^0.5.1                      # Background tasks
intl: ^0.19.0                            # Date formatting
```

## Permissions

### Android
- `INTERNET` - Fetch word definitions
- `POST_NOTIFICATIONS` - Show reinforcement notifications
- `RECEIVE_BOOT_COMPLETED` - Restart background tasks after reboot
- `WAKE_LOCK` - Keep background tasks running
- `SCHEDULE_EXACT_ALARM` - Schedule periodic notifications

### iOS
- Notification permissions requested at runtime

## Future Enhancements

Planned features for future versions:
- [ ] Delete word functionality
- [ ] Mark word as "learned"
- [ ] Quiz mode to test vocabulary
- [ ] Home screen widget
- [ ] English → Hindi translations
- [ ] Cloud sync across devices
- [ ] User accounts
- [ ] Customizable notification frequency
- [ ] Word pronunciation audio
- [ ] Usage examples and synonyms

## Troubleshooting

### Notifications not working
1. Ensure notification permissions are granted in device settings
2. Check that background tasks are not restricted for the app
3. Try the "Test Notification" feature (can be added to settings)

### Word not found error
- Verify internet connection
- Check spelling of the word
- Some very rare or slang words may not be in the dictionary

### Database issues
- Clear app data and restart
- Reinstall the app if problems persist

## License

This is an MVP project for personal vocabulary learning.

## Credits

- Dictionary data provided by [Free Dictionary API](https://dictionaryapi.dev/)
- Built with [Flutter](https://flutter.dev/)

