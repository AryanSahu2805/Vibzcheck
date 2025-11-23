import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'playlist_provider.dart';
import 'chat_provider.dart';
import '../services/firestore_service.dart';

// Auth Provider
final authProviderInstance = ChangeNotifierProvider((ref) => AuthProvider());

// Playlist Provider
final playlistProviderInstance = ChangeNotifierProvider((ref) => PlaylistProvider());

// Chat Provider
final chatProviderInstance = ChangeNotifierProvider((ref) => ChatProvider());

// Firestore Service
final firestoreServiceProvider = Provider((ref) => FirestoreService());

