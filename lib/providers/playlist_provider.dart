import 'package:flutter/material.dart';
import 'dart:async';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/spotify_service.dart';

class PlaylistProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final SpotifyService _spotifyService = SpotifyService();
  
  final List<PlaylistModel> _playlists = [];
  PlaylistModel? _currentPlaylist;
  List<SongModel> _currentSongs = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<SongModel>>? _songsSubscription;
  
  List<PlaylistModel> get playlists => _playlists;
  PlaylistModel? get currentPlaylist => _currentPlaylist;
  List<SongModel> get currentSongs => _currentSongs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  @override
  void dispose() {
    _songsSubscription?.cancel();
    super.dispose();
  }
  
  Future<String?> createPlaylist({
    required String name,
    String? description,
    String? coverImage,
    required String creatorId,
    required String creatorName,
    String? creatorProfilePicture,
    bool isPublic = false,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final playlistId = await _firestoreService.createPlaylist(
        name: name,
        description: description,
        coverImage: coverImage,
        creatorId: creatorId,
        creatorName: creatorName,
        creatorProfilePicture: creatorProfilePicture,
        isPublic: isPublic,
      );
      
      _isLoading = false;
      notifyListeners();
      return playlistId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  Future<void> loadPlaylist(String playlistId) async {
    try {
      // Cancel previous subscription
      await _songsSubscription?.cancel();
      _songsSubscription = null;
      
      _currentPlaylist = await _firestoreService.getPlaylist(playlistId);
      _isLoading = true;
      notifyListeners();
      
      // Listen to songs with new subscription
      _songsSubscription = _firestoreService.getPlaylistSongs(playlistId).listen((songs) {
        _currentSongs = songs;
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> addSong({
    required String playlistId,
    required Map<String, dynamic> trackData,
    required String userId,
    required String displayName,
  }) async {
    try {
      // Get audio features for mood tagging
      final audioFeatures = await _spotifyService.getAudioFeatures(trackData['id']);
      final moodTags = audioFeatures != null 
          ? _spotifyService.getMoodTags(audioFeatures)
          : <String>[];
      
      final song = SongModel(
        id: '',
        trackId: trackData['id'],
        trackName: trackData['name'],
        artistName: trackData['artists'][0]['name'],
        albumName: trackData['album']['name'],
        albumArtUrl: trackData['album']['images'][0]['url'],
        previewUrl: trackData['preview_url'],
        duration: Duration(milliseconds: trackData['duration_ms']),
        addedByUserId: userId,
        addedByDisplayName: displayName,
        addedAt: DateTime.now(),
        audioFeatures: audioFeatures,
        moodTags: moodTags,
      );
      
      await _firestoreService.addSong(playlistId: playlistId, song: song);
      
      // Send notification
      if (_currentPlaylist != null) {
        await _notificationService.sendSongAddedNotification(
          playlistId: playlistId,
          songName: song.trackName,
          addedBy: displayName,
          playlistName: _currentPlaylist!.name,
          currentUserId: userId,
        );
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> voteSong({
    required String playlistId,
    required String songId,
    required String userId,
    required bool isUpvote,
  }) async {
    try {
      await _firestoreService.voteSong(
        playlistId: playlistId,
        songId: songId,
        userId: userId,
        isUpvote: isUpvote,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<String?> joinPlaylist({
    required String shareCode,
    required String userId,
    required String displayName,
    String? profilePicture,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final playlistId = await _firestoreService.joinPlaylistByCode(
        shareCode: shareCode,
        userId: userId,
        displayName: displayName,
        profilePicture: profilePicture,
      );
      
      _isLoading = false;
      notifyListeners();
      return playlistId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}