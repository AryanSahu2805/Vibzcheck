import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // App Info
  static const String appName = 'Vibzcheck';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Collaborative Music, Democratic Vibes';
  
  // Spotify Configuration - Load from .env
  static String get spotifyClientId => 
      dotenv.env['SPOTIFY_CLIENT_ID'] ?? '316d9cd808124bf7b85df9428fc21a08';
  
  static String get spotifyClientSecret => 
      dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '6a1ea49e8e4944ea8ffbbbba848fb8d3';
  
  static String get spotifyRedirectUri => 
      dotenv.env['SPOTIFY_REDIRECT_URI'] ?? 'vibzcheck://callback';
  
  static const List<String> spotifyScopes = [
    'user-read-private',
    'user-read-email',
    'user-top-read',
    'playlist-read-private',
    'playlist-read-collaborative',
  ];
  
  static const String spotifyAuthUrl = 'https://accounts.spotify.com/authorize';
  static const String spotifyApiUrl = 'https://api.spotify.com/v1';
  
  // Cloudinary Configuration
  static String get cloudinaryCloudName => 
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'djhvg5ete';
  
  static String get cloudinaryApiKey => 
      dotenv.env['CLOUDINARY_API_KEY'] ?? '289947569678628';
  
  static String get cloudinaryApiSecret => 
      dotenv.env['CLOUDINARY_API_SECRET'] ?? 'Mc-nY08_0m6fTJuZQvp6cVT89r0';
  
  static String get cloudinaryUploadPreset => 
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'vibzcheck_preset';
  
  // Firebase Cloud Messaging
  static String get fcmServiceAccountPath => 
      dotenv.env['FCM_SERVICE_ACCOUNT_PATH'] ?? 'firebase-service-account.json';
  
  static String get fcmProjectId => 
      dotenv.env['FCM_PROJECT_ID'] ?? 'vibzcheck';
  
  static String get fcmSenderId => 
      dotenv.env['FCM_SENDER_ID'] ?? '28712650524';
  
  static const String fcmUrl = 'https://fcm.googleapis.com/v1/projects';
  
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String playlistsCollection = 'playlists';
  static const String songsCollection = 'songs';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String votesCollection = 'votes';
  static const String analyticsCollection = 'analytics';
  
  // Share Code Settings
  static const int shareCodeLength = 6;
  static const String shareCodeCharacters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const Duration shareCodeExpiration = Duration(hours: 24);
  
  // Playlist Settings
  static const int maxPlaylistSize = 100;
  static const int maxParticipants = 50;
  static const int minSongsForAnalytics = 5;
  
  // Vote Settings
  static const int upvoteValue = 1;
  static const int downvoteValue = -1;
  static const int maxVotesPerUser = 1; // Per song
  
  // Chat Settings
  static const int maxMessageLength = 500;
  static const int maxMessagesLoaded = 50;
  static const Duration typingIndicatorDuration = Duration(seconds: 3);
  
  // Audio Settings
  static const Duration previewDuration = Duration(seconds: 30);
  static const double defaultVolume = 0.7;
  
  // Image Settings
  static const int maxImageSizeMB = 5;
  static const int profileImageSize = 500; // pixels
  static const int playlistCoverSize = 800; // pixels
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Search Settings
  static const int searchResultsLimit = 20;
  static const int searchHistoryLimit = 10;
  static const Duration searchDebounce = Duration(milliseconds: 500);
  
  // Mood Tags (from Spotify Audio Features)
  static const Map<String, Map<String, dynamic>> moodTags = {
    'energetic': {
      'icon': '⚡',
      'color': 0xFFFF6B6B,
      'minEnergy': 0.7,
      'minValence': 0.5,
    },
    'chill': {
      'icon': '😌',
      'color': 0xFF4ECDC4,
      'maxEnergy': 0.5,
      'minValence': 0.4,
    },
    'happy': {
      'icon': '😊',
      'color': 0xFFFFA500,
      'minValence': 0.7,
    },
    'sad': {
      'icon': '😢',
      'color': 0xFF95A5A6,
      'maxValence': 0.3,
    },
    'party': {
      'icon': '🎉',
      'color': 0xFFE74C3C,
      'minEnergy': 0.8,
      'minDanceability': 0.7,
    },
    'focus': {
      'icon': '🎯',
      'color': 0xFF3498DB,
      'maxEnergy': 0.4,
      'minInstrumentalness': 0.5,
    },
  };
  
  // Notification Types
  static const String notifSongAdded = 'song_added';
  static const String notifVoteReceived = 'vote_received';
  static const String notifChatMention = 'chat_mention';
  static const String notifSongPlaying = 'song_playing';
  static const String notifUserJoined = 'user_joined';
  
  // Analytics Periods
  static const Duration analyticsDay = Duration(days: 1);
  static const Duration analyticsWeek = Duration(days: 7);
  static const Duration analyticsMonth = Duration(days: 30);
  
  // Pagination
  static const int playlistsPerPage = 10;
  static const int songsPerPage = 20;
  static const int usersPerPage = 20;
  
  // Cache Duration
  static const Duration imageCacheDuration = Duration(days: 7);
  static const Duration dataCacheDuration = Duration(hours: 1);
  
  // Error Messages
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorSpotify = 'Spotify connection error. Please try again.';
  static const String errorFirebase = 'Database error. Please try again.';
  static const String errorAuth = 'Authentication error. Please log in again.';
  static const String errorPermission = 'Permission denied.';
  static const String errorNotFound = 'Not found.';
  static const String errorGeneric = 'Something went wrong. Please try again.';
  
  // Success Messages
  static const String successPlaylistCreated = 'Playlist created successfully!';
  static const String successSongAdded = 'Song added to playlist!';
  static const String successVoted = 'Vote recorded!';
  static const String successJoined = 'Joined playlist!';
  static const String successLeft = 'Left playlist.';
  
  // Validation
  static const int minPlaylistNameLength = 3;
  static const int maxPlaylistNameLength = 50;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  
  // Regular Expressions
  static final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,30}$');
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // Developer Info
  static const String developerName = 'Vasu Singh';
  static const String developerEmail = 'vasu@vibzcheck.app';
  static const String githubUrl = 'https://github.com/vasusingh';
  static const String projectUrl = 'https://vibzcheck.app';
}