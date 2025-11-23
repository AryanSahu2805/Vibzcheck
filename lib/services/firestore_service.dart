import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import 'dart:math';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../models/chat_message_model.dart';
import '../config/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Generate unique share code
  String _generateShareCode() {
    final random = Random();
    return List.generate(
      AppConstants.shareCodeLength,
      (index) => AppConstants.shareCodeCharacters[
        random.nextInt(AppConstants.shareCodeCharacters.length)
      ],
    ).join();
  }
  
  // Create playlist
  Future<String> createPlaylist({
    required String name,
    String? description,
    String? coverImage,
    required String creatorId,
    required String creatorName,
    String? creatorProfilePicture,
    bool isPublic = false,
  }) async {
    try {
      final shareCode = _generateShareCode();
      
      final playlist = PlaylistModel(
        id: '',
        name: name,
        description: description,
        coverImage: coverImage,
        creatorId: creatorId,
        creatorName: creatorName,
        participants: [
          ParticipantModel(
            userId: creatorId,
            displayName: creatorName,
            profilePicture: creatorProfilePicture,
            joinedAt: DateTime.now(),
            role: 'creator',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        shareCode: shareCode,
        isPublic: isPublic,
      );
      
      final docRef = await _firestore
          .collection(AppConstants.playlistsCollection)
          .add(playlist.toFirestore());
      
      // Update user's playlist list
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(creatorId)
          .update({
        'playlistIds': FieldValue.arrayUnion([docRef.id]),
      });
      
      return docRef.id;
    } catch (e) {
      Logger.info('❌ Create playlist error: $e');
      rethrow;
    }
  }
  
  // Get playlist
  Future<PlaylistModel?> getPlaylist(String playlistId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.playlistsCollection)
          .doc(playlistId)
          .get();
      
      if (doc.exists) {
        return PlaylistModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.info('❌ Get playlist error: $e');
      return null;
    }
  }
  
  // Get playlist stream
  Stream<PlaylistModel?> getPlaylistStream(String playlistId) {
    return _firestore
        .collection(AppConstants.playlistsCollection)
        .doc(playlistId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return PlaylistModel.fromFirestore(doc);
      }
      return null;
    });
  }
  
  // Get user's playlists by reading user's playlistIds and fetching those docs.
  // This is more reliable than using arrayContains on a map element (which requires exact map match).
  Stream<List<PlaylistModel>> getUserPlaylists(String userId) async* {
    final userDocRef = _firestore.collection(AppConstants.usersCollection).doc(userId);

    await for (final userSnap in userDocRef.snapshots()) {
      final userData = userSnap.data();
      final rawIds = (userData != null && userData['playlistIds'] is List)
          ? List.from(userData['playlistIds']).where((e) => e != null).map((e) => e.toString()).toList()
          : <String>[];

      if (rawIds.isEmpty) {
        yield <PlaylistModel>[];
        continue;
      }

      // Firestore 'whereIn' supports up to 10 elements per query. Chunk if necessary.
      const chunkSize = 10;
      final chunks = <List<String>>[];
      for (var i = 0; i < rawIds.length; i += chunkSize) {
        chunks.add(rawIds.sublist(i, i + chunkSize > rawIds.length ? rawIds.length : i + chunkSize));
      }

      final List<PlaylistModel> results = [];
      for (final chunk in chunks) {
        final querySnapshot = await _firestore
            .collection(AppConstants.playlistsCollection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        results.addAll(querySnapshot.docs.map((d) => PlaylistModel.fromFirestore(d)));
      }

      // Sort by updatedAt descending to keep same behavior
      results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      yield results;
    }
  }
  
  // Join playlist by share code
  Future<String?> joinPlaylistByCode({
    required String shareCode,
    required String userId,
    required String displayName,
    String? profilePicture,
  }) async {
    try {
      final query = await _firestore
          .collection(AppConstants.playlistsCollection)
          .where('shareCode', isEqualTo: shareCode)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) {
        return null;
      }
      
      final playlistDoc = query.docs.first;
      final participant = ParticipantModel(
        userId: userId,
        displayName: displayName,
        profilePicture: profilePicture,
        joinedAt: DateTime.now(),
        role: 'member',
      );
      
      await playlistDoc.reference.update({
        'participants': FieldValue.arrayUnion([participant.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update user's playlist list
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'playlistIds': FieldValue.arrayUnion([playlistDoc.id]),
      });
      
      return playlistDoc.id;
    } catch (e) {
      Logger.info('❌ Join playlist error: $e');
      rethrow;
    }
  }
  
  // Add song to playlist
  Future<void> addSong({
    required String playlistId,
    required SongModel song,
  }) async {
    try {
      // Add song
      await _firestore
          .collection(AppConstants.playlistsCollection)
          .doc(playlistId)
          .collection(AppConstants.songsCollection)
          .add(song.toFirestore());
      
      // Update playlist song count
      await _firestore
          .collection(AppConstants.playlistsCollection)
          .doc(playlistId)
          .update({
        'songCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.info('❌ Add song error: $e');
      rethrow;
    }
  }
  
  // Get playlist songs (ordered by vote score)
  Stream<List<SongModel>> getPlaylistSongs(String playlistId) {
    return _firestore
        .collection(AppConstants.playlistsCollection)
        .doc(playlistId)
        .collection(AppConstants.songsCollection)
        .orderBy('voteScore', descending: true)
        .orderBy('addedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SongModel.fromFirestore(doc))
            .toList());
  }
  
  // Vote on song
  Future<void> voteSong({
    required String playlistId,
    required String songId,
    required String userId,
    required bool isUpvote,
  }) async {
    try {
      final songRef = _firestore
          .collection(AppConstants.playlistsCollection)
          .doc(playlistId)
          .collection(AppConstants.songsCollection)
          .doc(songId);
      
      final songDoc = await songRef.get();
      if (!songDoc.exists) return;
      
      final song = SongModel.fromFirestore(songDoc);
      
      // Remove previous vote if exists
      List<String> upvoters = List.from(song.upvoters);
      List<String> downvoters = List.from(song.downvoters);
      
      upvoters.remove(userId);
      downvoters.remove(userId);
      
      // Add new vote
      if (isUpvote) {
        upvoters.add(userId);
      } else {
        downvoters.add(userId);
      }
      
      // Calculate new score
      final voteScore = upvoters.length - downvoters.length;
      
      await songRef.update({
        'upvoters': upvoters,
        'downvoters': downvoters,
        'voteScore': voteScore,
      });
      
      // Update playlist timestamp
      await _firestore
          .collection(AppConstants.playlistsCollection)
          .doc(playlistId)
          .update({'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      Logger.info('❌ Vote song error: $e');
      rethrow;
    }
  }
  
  // Remove vote
  Future<void> removeVote({
    required String playlistId,
    required String songId,
    required String userId,
  }) async {
    try {
      final songRef = _firestore
          .collection(AppConstants.playlistsCollection)
          .doc(playlistId)
          .collection(AppConstants.songsCollection)
          .doc(songId);
      
      final songDoc = await songRef.get();
      if (!songDoc.exists) return;
      
      final song = SongModel.fromFirestore(songDoc);
      
      List<String> upvoters = List.from(song.upvoters);
      List<String> downvoters = List.from(song.downvoters);
      
      upvoters.remove(userId);
      downvoters.remove(userId);
      
      final voteScore = upvoters.length - downvoters.length;
      
      await songRef.update({
        'upvoters': upvoters,
        'downvoters': downvoters,
        'voteScore': voteScore,
      });
    } catch (e) {
      Logger.info('❌ Remove vote error: $e');
      rethrow;
    }
  }
  
  // Send chat message
  Future<void> sendMessage({
    required String playlistId,
    required ChatMessageModel message,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.playlistsCollection)
          .doc(playlistId)
          .collection(AppConstants.chatsCollection)
          .add(message.toFirestore());
      
      // Update playlist timestamp
      await _firestore
          .collection(AppConstants.playlistsCollection)
          .doc(playlistId)
          .update({'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      Logger.info('❌ Send message error: $e');
      rethrow;
    }
  }
  
  // Get chat messages
  Stream<List<ChatMessageModel>> getChatMessages(String playlistId, {int limit = 50}) {
    return _firestore
        .collection(AppConstants.playlistsCollection)
        .doc(playlistId)
        .collection(AppConstants.chatsCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList()
            .reversed
            .toList());
  }
  
  // Delete song
  Future<void> deleteSong({
    required String playlistId,
    required String songId,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.playlistsCollection)
          .doc(playlistId)
          .collection(AppConstants.songsCollection)
          .doc(songId)
          .delete();
      
      // Update song count
      await _firestore
          .collection(AppConstants.playlistsCollection)
          .doc(playlistId)
          .update({
        'songCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.info('❌ Delete song error: $e');
      rethrow;
    }
  }
  
  // Leave playlist
  Future<void> leavePlaylist({
    required String playlistId,
    required String userId,
  }) async {
    try {
      final playlistDoc = await _firestore
          .collection(AppConstants.playlistsCollection)
          .doc(playlistId)
          .get();
      
      if (!playlistDoc.exists) return;
      
      final playlist = PlaylistModel.fromFirestore(playlistDoc);
      final participants = playlist.participants
          .where((p) => p.userId != userId)
          .toList();
      
      await playlistDoc.reference.update({
        'participants': participants.map((p) => p.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update user's playlist list
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'playlistIds': FieldValue.arrayRemove([playlistId]),
      });
    } catch (e) {
      Logger.info('❌ Leave playlist error: $e');
      rethrow;
    }
  }
}