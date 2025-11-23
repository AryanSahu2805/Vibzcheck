import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class SongModel {
  final String id;
  final String trackId; // Spotify ID
  final String trackName;
  final String artistName;
  final String albumName;
  final String albumArtUrl;
  final String? previewUrl;
  final Duration duration;
  final String addedByUserId;
  final String addedByDisplayName;
  final DateTime addedAt;
  final int voteScore;
  final List<String> upvoters;
  final List<String> downvoters;
  final Map<String, dynamic>? audioFeatures;
  final List<String> moodTags;
  
  SongModel({
    required this.id,
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.albumArtUrl,
    this.previewUrl,
    required this.duration,
    required this.addedByUserId,
    required this.addedByDisplayName,
    required this.addedAt,
    this.voteScore = 0,
    this.upvoters = const [],
    this.downvoters = const [],
    this.audioFeatures,
    this.moodTags = const [],
  });
  
  factory SongModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) throw Exception('Song document data is null');
      
      // Safe conversion of List<Object?> to List<String>
      List<String> upvoters = [];
      final upvotersData = data['upvoters'];
      if (upvotersData != null && upvotersData is List) {
        upvoters = upvotersData
            .where((item) => item != null)
            .map((item) => item.toString())
            .toList();
      }
      
      List<String> downvoters = [];
      final downvotersData = data['downvoters'];
      if (downvotersData != null && downvotersData is List) {
        downvoters = downvotersData
            .where((item) => item != null)
            .map((item) => item.toString())
            .toList();
      }
      
      List<String> moodTags = [];
      final moodTagsData = data['moodTags'];
      if (moodTagsData != null && moodTagsData is List) {
        moodTags = moodTagsData
            .where((item) => item != null)
            .map((item) => item.toString())
            .toList();
      }
      
      return SongModel(
        id: doc.id,
        trackId: data['trackId'] ?? '',
        trackName: data['trackName'] ?? '',
        artistName: data['artistName'] ?? '',
        albumName: data['albumName'] ?? '',
        albumArtUrl: data['albumArtUrl'] ?? '',
        previewUrl: data['previewUrl'] as String?,
        duration: Duration(milliseconds: data['durationMs'] ?? 0),
        addedByUserId: data['addedByUserId'] ?? '',
        addedByDisplayName: data['addedByDisplayName'] ?? '',
        addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        voteScore: data['voteScore'] ?? 0,
        upvoters: upvoters,
        downvoters: downvoters,
        audioFeatures: data['audioFeatures'] as Map<String, dynamic>?,
        moodTags: moodTags,
      );
    } catch (e, st) {
      Logger.error('Error parsing SongModel from Firestore', e, st);
      rethrow;
    }
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'trackId': trackId,
      'trackName': trackName,
      'artistName': artistName,
      'albumName': albumName,
      'albumArtUrl': albumArtUrl,
      'previewUrl': previewUrl,
      'durationMs': duration.inMilliseconds,
      'addedByUserId': addedByUserId,
      'addedByDisplayName': addedByDisplayName,
      'addedAt': Timestamp.fromDate(addedAt),
      'voteScore': voteScore,
      'upvoters': upvoters,
      'downvoters': downvoters,
      'audioFeatures': audioFeatures,
      'moodTags': moodTags,
    };
  }
  
  String get durationText {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  
  SongModel copyWith({
    String? id,
    String? trackId,
    String? trackName,
    String? artistName,
    String? albumName,
    String? albumArtUrl,
    String? previewUrl,
    Duration? duration,
    String? addedByUserId,
    String? addedByDisplayName,
    DateTime? addedAt,
    int? voteScore,
    List<String>? upvoters,
    List<String>? downvoters,
    Map<String, dynamic>? audioFeatures,
    List<String>? moodTags,
  }) {
    return SongModel(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      trackName: trackName ?? this.trackName,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      previewUrl: previewUrl ?? this.previewUrl,
      duration: duration ?? this.duration,
      addedByUserId: addedByUserId ?? this.addedByUserId,
      addedByDisplayName: addedByDisplayName ?? this.addedByDisplayName,
      addedAt: addedAt ?? this.addedAt,
      voteScore: voteScore ?? this.voteScore,
      upvoters: upvoters ?? this.upvoters,
      downvoters: downvoters ?? this.downvoters,
      audioFeatures: audioFeatures ?? this.audioFeatures,
      moodTags: moodTags ?? this.moodTags,
    );
  }
}