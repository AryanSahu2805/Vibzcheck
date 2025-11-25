# 🎵 Vibzcheck

**Collaborative Music, Democratic Vibes**

---

## 📹 Video Demonstration

<!-- Add your video demonstration link here -->
[**Watch the App Demo**](https://drive.google.com/file/d/1offvN568zN49B3N5CIeeteyeLpd6YvWL/view?usp=share_link)
[**Watch the Presentation and Code Review**](https://drive.google.com/file/d/1asxbOTKIYx6_2xBAVxoaYqvUxiHIugZY/view?usp=share_link)

---

## 📖 About

Vibzcheck is a collaborative music playlist application built with Flutter that allows users to create, share, and manage playlists together in real-time. The app features a democratic voting system where participants can vote on songs, integrated Spotify search and preview functionality, real-time chat rooms, and automatic mood tagging for songs.

### Key Highlights

- 🎼 **Real-time Collaboration**: Multiple users can add songs and vote simultaneously
- 🗳️ **Democratic Voting**: Upvote/downvote songs to determine playlist order
- 🎧 **Spotify Integration**: Search millions of tracks and play 30-second previews
- 💬 **Live Chat**: Real-time messaging within playlists
- 🏷️ **Smart Tagging**: Automatic mood and genre tagging using Spotify audio features
- 📱 **Offline Support**: Cached preview playback for seamless experience

---

## ✨ Features

### Core Features

#### 🔐 User Authentication & Profiles
- Email/password authentication with Firebase
- User profiles with customizable display names and profile pictures
- Profile editing and management
- Session persistence and auto-login
- Secure authentication flow with error handling

#### 🎵 Collaborative Playlist System
- Create playlists with custom names, descriptions, and cover images
- Public/private playlist options
- **6-digit share code system** for easy joining
- Real-time participant management
- View all playlists you've created or joined
- Participant list with roles (creator/member)

#### 🗳️ Democratic Voting System
- Upvote and downvote buttons on each song
- Real-time vote synchronization across all users
- Automatic song ordering by vote score
- Vote state management (prevents duplicate votes)
- Vote scores cannot go negative (minimum is 0)
- Toggle voting (clicking same button removes vote)

#### 🎧 Spotify API Integration
- OAuth 2.0 authentication flow with Spotify
- Automatic token management and refresh
- Deep link handling for OAuth callbacks
- Search millions of Spotify tracks
- Get track details, album art, and metadata
- **30-second preview playback** with offline caching
- Audio features retrieval for mood analysis

#### 💬 Playlist Chat Rooms
- Real-time messaging with Firestore streams
- Message history with user attribution
- Profile pictures in chat messages
- Auto-scroll to latest messages
- Timestamp display for each message

#### 🏷️ Music Genre & Mood Tagging
- Automatic mood tag generation from Spotify audio features
- **Fallback metadata-based tagging** when audio features unavailable
- Mood tags: energetic, chill, happy, sad, party, focus
- Visual tag display with icons and styling
- Retroactive tag generation for existing songs
- Filter and sort playlists by vibe

### ⚡ Must-Solve Challenges (All Implemented)

1. **Real-time Vote Synchronization**
   - Firestore streams ensure instant updates across all clients
   - Optimistic UI updates for better UX
   - Conflict resolution for concurrent votes

2. **External Spotify API Integration**
   - Robust OAuth token management with persistence
   - Automatic token refresh on expiration
   - Retry mechanisms with exponential backoff
   - Graceful error handling and fallbacks

3. **Complex Playlist State Management**
   - Riverpod for dependency injection
   - ChangeNotifier providers for reactive state
   - Efficient UI updates with minimal rebuilds
   - Proper state synchronization with Firestore

4. **Caching & Offline Playback**
   - Local file caching for Spotify previews
   - Persistent storage using `path_provider`
   - Offline playback after initial download
   - Cache management and cleanup

### 🎁 Bonus Features

1. **Delete Playlist Functionality**
   - Creator-only playlist deletion
   - Cascading deletion of songs and chat messages
   - Automatic participant reference cleanup

2. **Delete Song Functionality**
   - Remove songs from playlists
   - Available to creator and song adder
   - Automatic vote score cleanup

3. **Retroactive Mood Tagging**
   - Update mood tags for existing songs
   - Batch update all songs in a playlist
   - Fallback tagging when API unavailable

4. **Enhanced Preview Playback**
   - Improved error messages
   - Better caching strategy
   - Track details fetching when preview URL missing

5. **Analytics Screen**
   - Playlist statistics and insights
   - Song count and participant metrics
   - Voting activity visualization

6. **Settings Screen**
   - App preferences and configuration
   - User account management
   - Notification settings

7. **Onboarding Experience**
   - Welcome screens for new users
   - Feature introduction and guidance
   - Smooth first-time user experience

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** (Dart 3.2+) - Cross-platform mobile framework
- **Riverpod** - State management and dependency injection
- **Provider** - Additional state management utilities

### Backend & Services
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - Real-time NoSQL database
- **Firebase Cloud Messaging** - Push notifications
- **Spotify Web API** - Music search and audio features
- **Cloudinary** - Image storage and CDN

### Key Dependencies
- `firebase_core`, `firebase_auth`, `cloud_firestore` - Firebase services
- `riverpod`, `flutter_riverpod` - State management
- `http`, `dio` - HTTP client for API calls
- `just_audio`, `path_provider` - Audio playback and caching
- `app_links` - Deep link handling
- `cloudinary_sdk` - Image upload and management
- `google_fonts` - Custom typography
- `cached_network_image` - Image caching
- `share_plus` - Social sharing
- `flutter_dotenv` - Environment variable management

---

## 📁 Project Structure

```
lib/
├── config/           # App configuration
│   ├── constants.dart    # App constants and configuration
│   ├── routes.dart       # Navigation routes
│   └── theme.dart        # App theme and styling
├── models/          # Data models
│   ├── user_model.dart
│   ├── playlist_model.dart
│   ├── song_model.dart
│   └── chat_message_model.dart
├── screens/         # UI screens
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── create_playlist_screen.dart
│   ├── playlist_view_screen.dart
│   ├── search_screen.dart
│   ├── chat_screen.dart
│   ├── profile_screen.dart
│   ├── analytics_screen.dart
│   └── settings_screen.dart
├── services/        # Business logic and API calls
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── spotify_service.dart
│   ├── audio_service.dart
│   ├── cloudinary_service.dart
│   ├── fcm_service.dart
│   └── notification_service.dart
├── providers/       # State management providers
│   ├── auth_provider.dart
│   ├── playlist_provider.dart
│   ├── chat_provider.dart
│   └── providers.dart
├── widgets/         # Reusable UI components
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── playlist_card.dart
│   ├── song_item.dart
│   ├── vote_button.dart
│   └── loading_indicator.dart
├── utils/           # Utility functions
│   ├── helpers.dart
│   ├── validators.dart
│   └── logger.dart
└── main.dart        # App entry point
```

**Total**: ~40 Dart files, ~9,200 lines of code

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.2.0)
- Dart SDK (>=3.2.0)
- Firebase project with Authentication and Firestore enabled
- Spotify Developer account with app credentials
- Cloudinary account for image storage

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/AryanSahu2805/Vibzcheck.git
   cd vibzcheck
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and provide the following values:
   ```env
   SPOTIFY_CLIENT_ID=your_spotify_client_id
   SPOTIFY_CLIENT_SECRET=your_spotify_client_secret
   SPOTIFY_REDIRECT_URI=vibzcheck://callback
   CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
   CLOUDINARY_UPLOAD_PRESET=your_cloudinary_upload_preset
   ```

4. **Firebase Setup**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files
   - Ensure Firebase Authentication (Email/Password) is enabled
   - Set up Firestore database with appropriate security rules
   - Configure Firebase Cloud Messaging for push notifications

5. **Run the app**
   ```bash
   flutter run
   ```

### Configuration Notes

- The project loads runtime secrets from a `.env` file
- Keep the `.env` file out of version control (already in `.gitignore`)
- If you see a "Configuration Error" screen on startup, verify that the `.env` file exists and contains all required variables
- Ensure deep link handling is configured in `AndroidManifest.xml` and `Info.plist` for Spotify OAuth callbacks

---

## 📱 Screenshots

<!-- Add screenshots of your app here -->
<!-- Example:
![Home Screen](screenshots/home.png)
![Playlist View](screenshots/playlist.png)
![Search](screenshots/search.png)
-->

---

## 🔑 Key Features Explained

### Share Code System
Each playlist gets a unique **6-digit alphanumeric share code** (A-Z, 0-9) that users can share to allow others to join. The code is generated using a secure random algorithm and stored with the playlist in Firestore.

**Location**: `lib/services/firestore_service.dart` - `_generateShareCode()` method

### Real-time Synchronization
All playlist data (songs, votes, chat messages) uses Firestore streams (`.snapshots()`) to ensure instant updates across all connected clients without manual refresh.

### Mood Tagging Algorithm
The app uses Spotify's audio features API to analyze tracks and generate mood tags. If the API is unavailable, it falls back to metadata-based tagging using track name, artist, and album information.

**Location**: `lib/services/spotify_service.dart` - `getMoodTags()` and `getMoodTagsFromMetadata()` methods

### Offline Preview Caching
30-second song previews are downloaded and cached locally using `just_audio` and `path_provider`. Once cached, previews can be played offline.

**Location**: `lib/services/audio_service.dart` - `_downloadAndCache()` method

---

## 🧪 Testing

To test the app functionality:

1. **User Authentication**: Sign up with email/password, then sign in
2. **Create Playlist**: Create a new playlist with name and description
3. **Join Playlist**: Use the 6-digit share code to join a playlist
4. **Add Songs**: Search Spotify and add songs to playlists
5. **Vote**: Upvote/downvote songs and see real-time vote updates
6. **Chat**: Send messages in playlist chat rooms
7. **Preview**: Play 30-second song previews
8. **Mood Tags**: View automatically generated mood tags on songs

---

## 📝 License

This project is created for academic purposes.

---

## 👤 Author

**Aryan Sahu**

- GitHub: [@AryanSahu2805](https://github.com/AryanSahu2805)

---

## 🙏 Acknowledgments

- Spotify for the comprehensive Web API
- Firebase for backend infrastructure
- Cloudinary for image storage solutions
- Flutter team for the amazing framework
- All open-source contributors whose packages made this project possible

---

## 📚 Additional Documentation

- [Bonus Features Documentation](BONUS_FEATURES.md) - Detailed documentation of all bonus features
- [AI Usage Log](AI_USAGE_LOG.md) - Transparent documentation of AI assistance used in development

---

**Built with ❤️ using Flutter**
