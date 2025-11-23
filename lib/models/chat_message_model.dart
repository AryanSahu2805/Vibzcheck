import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class ChatMessageModel {
  final String id;
  final String playlistId;
  final String userId;
  final String displayName;
  final String? profilePicture;
  final String message;
  final DateTime timestamp;
  final List<String> mentions;
  final String? replyToMessageId;
  
  ChatMessageModel({
    required this.id,
    required this.playlistId,
    required this.userId,
    required this.displayName,
    this.profilePicture,
    required this.message,
    required this.timestamp,
    this.mentions = const [],
    this.replyToMessageId,
  });
  
  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) throw Exception('Chat message document data is null');
      
      // Safe conversion of List<Object?> to List<String>
      List<String> mentions = [];
      final mentionsData = data['mentions'];
      if (mentionsData != null && mentionsData is List) {
        mentions = mentionsData
            .where((item) => item != null)
            .map((item) => item.toString())
            .toList();
      }
      
      return ChatMessageModel(
        id: doc.id,
        playlistId: data['playlistId'] ?? '',
        userId: data['userId'] ?? '',
        displayName: data['displayName'] ?? '',
        profilePicture: data['profilePicture'] as String?,
        message: data['message'] ?? '',
        timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        mentions: mentions,
        replyToMessageId: data['replyToMessageId'] as String?,
      );
    } catch (e, st) {
      Logger.error('Error parsing ChatMessageModel from Firestore', e, st);
      rethrow;
    }
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'playlistId': playlistId,
      'userId': userId,
      'displayName': displayName,
      'profilePicture': profilePicture,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'mentions': mentions,
      'replyToMessageId': replyToMessageId,
    };
  }
}