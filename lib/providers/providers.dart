import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'playlist_provider.dart';
import 'chat_provider.dart';
import '../services/firestore_service.dart';
import '../services/spotify_service.dart';

// Spotify Service (singleton to share token across app)
final _spotifyServiceInstance = SpotifyService();
final spotifyServiceProvider = Provider<SpotifyService>((ref) {
  return _spotifyServiceInstance;
});

// Export singleton instance for use in non-provider classes
SpotifyService get spotifyServiceInstance => _spotifyServiceInstance;

// Auth Provider
final authProviderInstance = ChangeNotifierProvider((ref) => AuthProvider());

// Playlist Provider
final playlistProviderInstance = ChangeNotifierProvider((ref) => PlaylistProvider());

// Chat Provider
final chatProviderInstance = ChangeNotifierProvider((ref) => ChatProvider());

// Firestore Service
final firestoreServiceProvider = Provider((ref) => FirestoreService());

