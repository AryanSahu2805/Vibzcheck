import 'package:cloud_firestore/cloud_firestore.dart';

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
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatMessageModel(
      id: doc.id,
      playlistId: data['playlistId'] ?? '',
      userId: data['userId'] ?? '',
      displayName: data['displayName'] ?? '',
      profilePicture: data['profilePicture'],
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mentions: List<String>.from(data['mentions'] ?? []),
      replyToMessageId: data['replyToMessageId'],
    );
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