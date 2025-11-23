import 'dart:io';
import '../utils/logger.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../config/constants.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentSongId;
  bool _isPlaying = false;
  
  // Get current player state
  bool get isPlaying => _isPlaying;
  String? get currentSongId => _currentSongId;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  
  // Cache directory
  Future<Directory> get _cacheDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, 'audio_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }
  
  // Get cached file path
  Future<File?> _getCachedFile(String songId) async {
    final cacheDir = await _cacheDir;
    final file = File(path.join(cacheDir.path, '$songId.mp3'));
    if (await file.exists()) {
      return file;
    }
    return null;
  }
  
  // Download and cache preview
  Future<File?> _downloadAndCache(String songId, String previewUrl) async {
    try {
      final cacheDir = await _cacheDir;
      final file = File(path.join(cacheDir.path, '$songId.mp3'));
      
      // Check if already cached
      if (await file.exists()) {
        return file;
      }
      
      // Download preview
      final response = await http.get(Uri.parse(previewUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
      
      return null;
    } catch (e) {
      Logger.info('❌ Download and cache error: $e');
      return null;
    }
  }
  
  // Play preview (30 seconds max)
  Future<void> playPreview({
    required String songId,
    required String? previewUrl,
  }) async {
    try {
      // Stop current playback
      await stop();
      
      if (previewUrl == null || previewUrl.isEmpty) {
        throw Exception('No preview URL available for this song');
      }
      
      _currentSongId = songId;
      
      // Try to get cached file first
      File? audioFile = await _getCachedFile(songId);
      
      // If not cached, download and cache
      audioFile ??= await _downloadAndCache(songId, previewUrl);
      
      if (audioFile == null) {
        throw Exception('Failed to load preview');
      }
      
      // Load and play
      await _player.setFilePath(audioFile.path);
      
      // Set max duration to 30 seconds
      _player.setClip(start: Duration.zero, end: AppConstants.previewDuration);
      
      await _player.play();
      _isPlaying = true;
      
      // Auto-stop after 30 seconds
      _player.positionStream.listen((position) {
        if (position >= AppConstants.previewDuration) {
          stop();
        }
      });
      
    } catch (e) {
      Logger.info('❌ Play preview error: $e');
      _isPlaying = false;
      _currentSongId = null;
      rethrow;
    }
  }
  
  // Pause playback
  Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (e) {
      Logger.info('❌ Pause error: $e');
    }
  }
  
  // Resume playback
  Future<void> resume() async {
    try {
      await _player.play();
      _isPlaying = true;
    } catch (e) {
      Logger.info('❌ Resume error: $e');
    }
  }
  
  // Stop playback
  Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentSongId = null;
    } catch (e) {
      Logger.info('❌ Stop error: $e');
    }
  }
  
  // Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      Logger.info('❌ Seek error: $e');
    }
  }
  
  // Pre-cache preview (for offline playback)
  Future<bool> preCachePreview(String songId, String previewUrl) async {
    try {
      final cachedFile = await _getCachedFile(songId);
      if (cachedFile != null) {
        return true; // Already cached
      }
      
      final file = await _downloadAndCache(songId, previewUrl);
      return file != null;
    } catch (e) {
      Logger.info('❌ Pre-cache error: $e');
      return false;
    }
  }
  
  // Clear cache
  Future<void> clearCache() async {
    try {
      final cacheDir = await _cacheDir;
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }
    } catch (e) {
      Logger.info('❌ Clear cache error: $e');
    }
  }
  
  // Get cache size
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await _cacheDir;
      if (!await cacheDir.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      Logger.info('❌ Get cache size error: $e');
      return 0;
    }
  }
  
  // Dispose
  void dispose() {
    _player.dispose();
  }
}

