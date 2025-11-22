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

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String playlistView = '/playlist-view';
  static const String createPlaylist = '/create-playlist';
  static const String chat = '/chat';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String analytics = '/analytics';
  
  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
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
        final args = settings.arguments as Map<String, dynamic>?;
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
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            playlistId: args?['playlistId'] ?? '',
            playlistName: args?['playlistName'] ?? 'Chat',
          ),
        );
        
      case search:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SearchScreen(
            playlistId: args?['playlistId'],
          ),
        );
        
      case profile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(
            userId: args?['userId'],
          ),
        );
        
      case analytics:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AnalyticsScreen(
            playlistId: args?['playlistId'] ?? '',
          ),
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
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
}