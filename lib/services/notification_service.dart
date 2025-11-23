import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import 'fcm_service.dart';
import '../config/constants.dart';

class NotificationService {
  final FCMService _fcmService = FCMService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Send song added notification
  Future<void> sendSongAddedNotification({
    required String playlistId,
    required String songName,
    required String addedBy,
    required String playlistName,
    required String currentUserId,
  }) async {
    try {
      final participants = await _getPlaylistParticipantTokens(
        playlistId,
        excludeUserId: currentUserId,
      );
      
      await _fcmService.sendToMultipleTokens(
        fcmTokens: participants,
        title: '🎵 New Song Added',
        body: '$addedBy added "$songName" to $playlistName',
        data: {
          'type': AppConstants.notifSongAdded,
          'playlistId': playlistId,
          'songName': songName,
        },
      );
    } catch (e) {
      Logger.info('❌ Send song added notification error: $e');
    }
  }
  
  // Send vote notification
  Future<void> sendVoteNotification({
    required String songOwnerId,
    required String songName,
    required bool isUpvote,
  }) async {
    try {
      final fcmToken = await _getUserFCMToken(songOwnerId);
      if (fcmToken == null) return;
      
      await _fcmService.sendNotification(
        fcmToken: fcmToken,
        title: isUpvote ? '⬆️ Upvote!' : '⬇️ Downvote',
        body: 'Your song "$songName" received ${isUpvote ? "an upvote" : "a downvote"}!',
        data: {
          'type': AppConstants.notifVoteReceived,
          'songName': songName,
        },
      );
    } catch (e) {
      Logger.info('❌ Send vote notification error: $e');
    }
  }
  
  // Send chat mention notification
  Future<void> sendMentionNotification({
    required String mentionedUserId,
    required String mentionedBy,
    required String playlistId,
    required String playlistName,
  }) async {
    try {
      final fcmToken = await _getUserFCMToken(mentionedUserId);
      if (fcmToken == null) return;
      
      await _fcmService.sendNotification(
        fcmToken: fcmToken,
        title: '💬 Mentioned in Chat',
        body: '$mentionedBy mentioned you in $playlistName',
        data: {
          'type': AppConstants.notifChatMention,
          'playlistId': playlistId,
        },
      );
    } catch (e) {
      Logger.info('❌ Send mention notification error: $e');
    }
  }
  
  // Send user joined notification
  Future<void> sendUserJoinedNotification({
    required String playlistId,
    required String playlistName,
    required String userName,
    required String currentUserId,
  }) async {
    try {
      final participants = await _getPlaylistParticipantTokens(
        playlistId,
        excludeUserId: currentUserId,
      );
      
      await _fcmService.sendToMultipleTokens(
        fcmTokens: participants,
        title: '👋 New Member',
        body: '$userName joined $playlistName',
        data: {
          'type': AppConstants.notifUserJoined,
          'playlistId': playlistId,
        },
      );
    } catch (e) {
      Logger.info('❌ Send user joined notification error: $e');
    }
  }
  
  // Get playlist participant FCM tokens
  Future<List<String>> _getPlaylistParticipantTokens(
    String playlistId, {
    String? excludeUserId,
  }) async {
    try {
      final playlistDoc = await _firestore
          .collection(AppConstants.playlistsCollection)
          .doc(playlistId)
          .get();
      
      if (!playlistDoc.exists) return [];
      
      final participants = playlistDoc.data()?['participants'] as List? ?? [];
      final userIds = participants
          .map((p) => p['userId'] as String)
          .where((id) => id != excludeUserId)
          .toList();
      
      final List<String> tokens = [];
      
      for (final userId in userIds) {
        final token = await _getUserFCMToken(userId);
        if (token != null) {
          tokens.add(token);
        }
      }
      
      return tokens;
    } catch (e) {
      Logger.info('❌ Get participant tokens error: $e');
      return [];
    }
  }
  
  // Get user FCM token
  Future<String?> _getUserFCMToken(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      return userDoc.data()?['fcmToken'] as String?;
    } catch (e) {
      Logger.info('❌ Get user FCM token error: $e');
      return null;
    }
  }
}