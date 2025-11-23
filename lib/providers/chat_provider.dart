import 'package:flutter/material.dart';
import '../utils/logger.dart';
import '../models/chat_message_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class ChatProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  
  final List<ChatMessageModel> _messages = [];
  final bool _isLoading = false;
  
  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  
  void loadMessages(String playlistId) {
    _firestoreService.getChatMessages(playlistId).listen((messages) {
      _messages.clear();
      _messages.addAll(messages);
      notifyListeners();
    });
  }
  
  Future<void> sendMessage({
    required String playlistId,
    required String playlistName,
    required String userId,
    required String displayName,
    String? profilePicture,
    required String messageText,
  }) async {
    try {
      // Extract mentions
      final mentions = _extractMentions(messageText);
      
      final message = ChatMessageModel(
        id: '',
        playlistId: playlistId,
        userId: userId,
        displayName: displayName,
        profilePicture: profilePicture,
        message: messageText,
        timestamp: DateTime.now(),
        mentions: mentions,
      );
      
      await _firestoreService.sendMessage(
        playlistId: playlistId,
        message: message,
      );
      
      // Send notifications to mentioned users
      for (final mentionedUserId in mentions) {
        await _notificationService.sendMentionNotification(
          mentionedUserId: mentionedUserId,
          mentionedBy: displayName,
          playlistId: playlistId,
          playlistName: playlistName,
        );
      }
    } catch (e) {
      Logger.info('❌ Send message error: $e');
    }
  }
  
  List<String> _extractMentions(String text) {
    // Simple mention extraction (@username pattern)
    final pattern = RegExp(r'@(\w+)');
    final matches = pattern.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }
}