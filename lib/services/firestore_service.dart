import 'package:cloud_firestore/cloud_firestore.dart';
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
      print('❌ Create playlist error: $e');
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
      print('❌ Get playlist error: $e');
      return null;
    }
  }
  
  // Get user's playlists
  Stream<List<PlaylistModel>> getUserPlaylists(String userId) {
    return _firestore
        .collection(AppConstants.playlistsCollection)
        .where('participants', arrayContains: {
          'userId': userId,
        })
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PlaylistModel.fromFirestore(doc))
            .toList());
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
      print('❌ Join playlist error: $e');
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
      print('❌ Add song error: $e');
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
      print('❌ Vote song error: $e');
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
      print('❌ Remove vote error: $e');
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
      print('❌ Send message error: $e');
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
      print('❌ Delete song error: $e');
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
      print('❌ Leave playlist error: $e');
      rethrow;
    }
  }
}