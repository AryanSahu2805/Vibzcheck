import 'package:flutter/material.dart';
import 'dart:async';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/spotify_service.dart';
import '../utils/logger.dart';

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
      final trackId = trackData['id'] as String;
      Logger.info('🎵 Adding song: ${trackData['name']} (ID: $trackId)');
      
      // Extract preview URL - check both 'preview_url' and 'previewUrl'
      String? previewUrl = trackData['preview_url'] as String?;
      if (previewUrl == null || previewUrl.isEmpty) {
        previewUrl = trackData['previewUrl'] as String?;
      }
      
      // If preview URL is missing, try to fetch track details
      if ((previewUrl == null || previewUrl.isEmpty) && trackId.isNotEmpty) {
        Logger.info('📡 Preview URL missing, fetching track details...');
        try {
          final trackDetails = await _spotifyService.getTrackDetails(trackId);
          if (trackDetails != null) {
            previewUrl = trackDetails['preview_url'] as String?;
            if (previewUrl != null && previewUrl.isNotEmpty) {
              Logger.success('✅ Got preview URL from track details');
            }
          }
        } catch (e) {
          Logger.warning('⚠️ Could not fetch track details: $e');
        }
      }
      
      if (previewUrl != null && previewUrl.isNotEmpty) {
        Logger.success('✅ Preview URL found: ${previewUrl.substring(0, 50)}...');
      } else {
        Logger.warning('⚠️ No preview URL available for: ${trackData['name']}');
      }
      
      // Get audio features for mood tagging (with error handling)
      Map<String, dynamic>? audioFeatures;
      List<String> moodTags = [];
      
      try {
        audioFeatures = await _spotifyService.getAudioFeatures(trackId);
        if (audioFeatures != null) {
          moodTags = _spotifyService.getMoodTags(audioFeatures);
          Logger.success('✅ Got ${moodTags.length} mood tags from audio features: $moodTags');
        } else {
          Logger.warning('⚠️ Could not get audio features for track: $trackId');
        }
      } catch (e) {
        Logger.warning('⚠️ Error getting audio features: $e');
        // Will use fallback metadata-based tagging
      }
      
      // Fallback: Use metadata-based mood tagging if audio features failed
      if (moodTags.isEmpty) {
        Logger.info('🔄 Using fallback metadata-based mood tagging...');
        try {
          // Extract genres from track data if available
          final album = trackData['album'] as Map<String, dynamic>?;
          final artists = trackData['artists'] as List<dynamic>?;
          List<String>? genres;
          
          // Try to get genres from album
          if (album != null && album.containsKey('genres')) {
            final albumGenres = album['genres'] as List<dynamic>?;
            if (albumGenres != null && albumGenres.isNotEmpty) {
              genres = albumGenres.map((g) => g.toString()).toList();
            }
          }
          
          // Try to get genres from artists
          if ((genres == null || genres.isEmpty) && artists != null && artists.isNotEmpty) {
            final artist = artists[0] as Map<String, dynamic>?;
            if (artist != null && artist.containsKey('genres')) {
              final artistGenres = artist['genres'] as List<dynamic>?;
              if (artistGenres != null && artistGenres.isNotEmpty) {
                genres = artistGenres.map((g) => g.toString()).toList();
              }
            }
          }
          
          moodTags = _spotifyService.getMoodTagsFromMetadata(
            trackName: trackData['name'] as String,
            artistName: artists != null && artists.isNotEmpty 
                ? artists[0]['name'] as String 
                : 'Unknown',
            albumName: album?['name'] as String?,
            genres: genres,
          );
          
          Logger.success('✅ Generated ${moodTags.length} mood tags from metadata: $moodTags');
        } catch (e) {
          Logger.error('❌ Error generating mood tags from metadata', e, null);
          // Still continue - song will be added without tags
        }
      }
      
      final song = SongModel(
        id: '',
        trackId: trackId,
        trackName: trackData['name'] as String,
        artistName: trackData['artists'][0]['name'] as String,
        albumName: trackData['album']['name'] as String,
        albumArtUrl: trackData['album']['images'][0]['url'] as String,
        previewUrl: previewUrl,
        duration: Duration(milliseconds: trackData['duration_ms'] as int),
        addedByUserId: userId,
        addedByDisplayName: displayName,
        addedAt: DateTime.now(),
        audioFeatures: audioFeatures,
        moodTags: moodTags,
      );
      
      await _firestoreService.addSong(playlistId: playlistId, song: song);
      Logger.success('✅ Song added successfully with ${moodTags.length} mood tags');
      
      // Reload playlist to update song count
      if (playlistId == _currentPlaylist?.id) {
        _currentPlaylist = await _firestoreService.getPlaylist(playlistId);
        notifyListeners();
      }
      
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
  
  Future<void> deleteSong({
    required String playlistId,
    required String songId,
  }) async {
    try {
      await _firestoreService.deleteSong(
        playlistId: playlistId,
        songId: songId,
      );
      
      // Reload playlist to update song count
      if (playlistId == _currentPlaylist?.id) {
        _currentPlaylist = await _firestoreService.getPlaylist(playlistId);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      Logger.error('Delete song error', e, null);
    }
  }
  
  // Update song with mood tags (for retroactive tagging)
  Future<void> updateSongMoodTags({
    required String playlistId,
    required String songId,
  }) async {
    try {
      // Get the song to find its trackId
      final songs = await _firestoreService.getPlaylistSongs(playlistId).first;
      final song = songs.firstWhere((s) => s.id == songId);
      
      if (song.trackId.isEmpty) {
        Logger.warning('⚠️ Song has no trackId, cannot fetch mood tags');
        return;
      }
      
      Logger.info('🔄 Fetching mood tags for song: ${song.trackName}');
      
      // Get audio features and generate mood tags
      Map<String, dynamic>? audioFeatures;
      List<String> moodTags = [];
      
      try {
        audioFeatures = await _spotifyService.getAudioFeatures(song.trackId);
        if (audioFeatures != null) {
          moodTags = _spotifyService.getMoodTags(audioFeatures);
          Logger.success('✅ Generated ${moodTags.length} mood tags from audio features: $moodTags');
        }
      } catch (e) {
        Logger.warning('⚠️ Could not get audio features: $e');
      }
      
      // Fallback to metadata-based tagging if audio features failed
      if (moodTags.isEmpty) {
        Logger.info('🔄 Using fallback metadata-based mood tagging...');
        moodTags = _spotifyService.getMoodTagsFromMetadata(
          trackName: song.trackName,
          artistName: song.artistName,
          albumName: song.albumName,
          genres: null, // We don't have genre info in SongModel
        );
        Logger.success('✅ Generated ${moodTags.length} mood tags from metadata: $moodTags');
      }
      
      // Update the song in Firestore
      await _firestoreService.updateSongMoodTags(
        playlistId: playlistId,
        songId: songId,
        moodTags: moodTags,
        audioFeatures: audioFeatures,
      );
      
      // Reload playlist to show updated tags
      if (playlistId == _currentPlaylist?.id) {
        await loadPlaylist(playlistId);
      }
    } catch (e) {
      Logger.error('❌ Update song mood tags error', e, null);
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Update all songs in playlist with mood tags (for retroactive tagging)
  Future<void> updateAllSongsMoodTags({
    required String playlistId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      Logger.info('🔄 Updating mood tags for all songs in playlist...');
      
      // Get all songs
      final songs = await _firestoreService.getPlaylistSongs(playlistId).first;
      int updated = 0;
      int failed = 0;
      
      for (final song in songs) {
        // Skip if song already has mood tags
        if (song.moodTags.isNotEmpty) {
          Logger.debug('⏭️ Song ${song.trackName} already has mood tags, skipping');
          continue;
        }
        
        if (song.trackId.isEmpty) {
          Logger.warning('⚠️ Song ${song.trackName} has no trackId, skipping');
          failed++;
          continue;
        }
        
        try {
          // Get audio features and generate mood tags
          Map<String, dynamic>? audioFeatures;
          List<String> moodTags = [];
          
          try {
            audioFeatures = await _spotifyService.getAudioFeatures(song.trackId);
            if (audioFeatures != null) {
              moodTags = _spotifyService.getMoodTags(audioFeatures);
            }
          } catch (e) {
            Logger.warning('⚠️ Audio features failed for ${song.trackName}, using fallback');
          }
          
          // Fallback to metadata-based tagging if audio features failed
          if (moodTags.isEmpty) {
            moodTags = _spotifyService.getMoodTagsFromMetadata(
              trackName: song.trackName,
              artistName: song.artistName,
              albumName: song.albumName,
              genres: null,
            );
          }
          
          if (moodTags.isNotEmpty) {
            // Update the song in Firestore
            await _firestoreService.updateSongMoodTags(
              playlistId: playlistId,
              songId: song.id,
              moodTags: moodTags,
              audioFeatures: audioFeatures,
            );
            updated++;
            Logger.success('✅ Updated tags for: ${song.trackName} - $moodTags');
          } else {
            failed++;
            Logger.warning('⚠️ Could not generate mood tags for: ${song.trackName}');
          }
        } catch (e) {
          failed++;
          Logger.error('❌ Error updating tags for ${song.trackName}', e, null);
        }
      }
      
      Logger.success('✅ Updated mood tags: $updated successful, $failed failed');
      
      // Reload playlist to show updated tags
      if (playlistId == _currentPlaylist?.id) {
        await loadPlaylist(playlistId);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      Logger.error('❌ Update all songs mood tags error', e, null);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> deletePlaylist({
    required String playlistId,
    required String userId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.deletePlaylist(
        playlistId: playlistId,
        userId: userId,
      );
      
      // Clear current playlist if it was deleted
      if (playlistId == _currentPlaylist?.id) {
        _currentPlaylist = null;
        _currentSongs = [];
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      Logger.error('Delete playlist error', e, null);
      rethrow;
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}