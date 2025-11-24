import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/playlist_view_screen.dart';
import '../screens/create_playlist_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/search_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/settings_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String playlistView = '/playlist-view';
  static const String createPlaylist = '/create-playlist';
  static const String settings = '/settings';
  static const String chat = '/chat';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String analytics = '/analytics';
  static const String spotifyCallback = '/callback';
  
  // Route generator
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    // Handle Spotify OAuth callback - extract route name without query params
    String routeName = routeSettings.name ?? '/';
    
    // Parse URI to check for query parameters
    Uri? uri;
    if (routeSettings.name != null) {
      // Try parsing as full URI first (for deep links like vibzcheck://callback?code=...)
      uri = Uri.tryParse(routeSettings.name!);
      if (uri == null || uri.scheme.isEmpty) {
        // If not a full URI, try as path with query
        uri = Uri.tryParse('/${routeSettings.name}');
      }
      
      // Extract route name without query params
      if (routeName.contains('?')) {
        routeName = routeName.split('?').first;
      }
      // Also check if it's a deep link path
      if (uri != null && uri.path.isNotEmpty) {
        routeName = uri.path;
        if (routeName.isEmpty || routeName == '/') {
          routeName = '/';
        }
      }
    }
    
    // Check if this is a Spotify callback (has code parameter)
    if (uri != null && uri.queryParameters.containsKey('code')) {
      // Check if it's the callback path or root with code
      final path = uri.path.isEmpty ? '/' : uri.path;
      if (path == '/' || path == '/callback' || uri.host == 'callback') {
        // This is a Spotify OAuth callback - handle it silently
        // The SpotifyService listener will pick it up
        return MaterialPageRoute(
          builder: (_) => const _SpotifyCallbackHandler(),
        );
      }
    }
    
    switch (routeName) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
        
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );
        
      case auth:
        return MaterialPageRoute(
          builder: (_) => const AuthScreen(),
        );
        
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
        
      case playlistView:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PlaylistViewScreen(
            playlistId: args?['playlistId'] ?? '',
          ),
        );
        
      case createPlaylist:
        return MaterialPageRoute(
          builder: (_) => const CreatePlaylistScreen(),
        );
        
      case chat:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            playlistId: args?['playlistId'] ?? '',
            playlistName: args?['playlistName'] ?? 'Chat',
          ),
        );
        
      case search:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SearchScreen(
            playlistId: args?['playlistId'],
          ),
        );
        
      case profile:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(
            userId: args?['userId'],
          ),
        );
        
      case analytics:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AnalyticsScreen(
            playlistId: args?['playlistId'] ?? '',
          ),
        );
        
      case settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );
        
      case spotifyCallback:
        // Handle Spotify callback route
        return MaterialPageRoute(
          builder: (_) => const _SpotifyCallbackHandler(),
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
  
  // Navigation helpers
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      home,
      (route) => false,
    );
  }
  
  static void navigateToAuth(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      auth,
      (route) => false,
    );
  }
  
  static void navigateToPlaylist(BuildContext context, String playlistId) {
    Navigator.pushNamed(
      context,
      playlistView,
      arguments: {'playlistId': playlistId},
    );
  }
  
  static void navigateToChat(
    BuildContext context,
    String playlistId,
    String playlistName,
  ) {
    Navigator.pushNamed(
      context,
      chat,
      arguments: {
        'playlistId': playlistId,
        'playlistName': playlistName,
      },
    );
  }
  
  static void navigateToSearch(BuildContext context, {String? playlistId}) {
    Navigator.pushNamed(
      context,
      search,
      arguments: {'playlistId': playlistId},
    );
  }
  
  static void navigateToProfile(BuildContext context, {String? userId}) {
    Navigator.pushNamed(
      context,
      profile,
      arguments: {'userId': userId},
    );
  }
  
  static void navigateToAnalytics(BuildContext context, String playlistId) {
    Navigator.pushNamed(
      context,
      analytics,
      arguments: {'playlistId': playlistId},
    );
  }
  
  static void navigateToSettings(BuildContext context) {
    Navigator.pushNamed(context, settings);
  }
}

// Widget to handle Spotify OAuth callback
// This widget doesn't render anything visible - it just allows the deep link
// to be processed by the SpotifyService listener
class _SpotifyCallbackHandler extends StatefulWidget {
  const _SpotifyCallbackHandler();

  @override
  State<_SpotifyCallbackHandler> createState() => _SpotifyCallbackHandlerState();
}

class _SpotifyCallbackHandlerState extends State<_SpotifyCallbackHandler> {
  @override
  void initState() {
    super.initState();
    // Navigate back to the previous screen or home after a brief delay
    // The SpotifyService listener will handle the actual callback
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => 
          route.settings.name == AppRoutes.home || 
          route.settings.name == AppRoutes.search ||
          route.isFirst
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while processing
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1DB954),
        ),
      ),
    );
  }
}