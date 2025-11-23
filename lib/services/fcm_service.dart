import 'dart:convert';
import '../utils/logger.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../config/constants.dart';

class FCMService {
  String? _accessToken;
  DateTime? _tokenExpiry;
  
  // Get OAuth 2.0 access token
  Future<String> _getAccessToken() async {
    try {
      // Check if token is still valid
      if (_accessToken != null && 
          _tokenExpiry != null && 
          DateTime.now().isBefore(_tokenExpiry!)) {
        return _accessToken!;
      }
      
      // Read service account JSON
      final serviceAccountJson = await rootBundle.loadString(
        AppConstants.fcmServiceAccountPath,
      );
      final accountCredentials = ServiceAccountCredentials.fromJson(
        json.decode(serviceAccountJson),
      );
      
      // Get access token
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      
      _accessToken = client.credentials.accessToken.data;
      _tokenExpiry = client.credentials.accessToken.expiry;
      
      client.close();
      
      return _accessToken!;
    } catch (e) {
      Logger.info('❌ Get access token error: $e');
      rethrow;
    }
  }
  
  // Send notification using FCM V1 API
  Future<bool> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      
      final response = await http.post(
        Uri.parse('${AppConstants.fcmUrl}/${AppConstants.fcmProjectId}/messages:send'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': {
            'token': fcmToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': data ?? {},
            'android': {
              'priority': 'high',
              'notification': {
                'sound': 'default',
                'color': '#1DB954',
              },
            },
          },
        }),
      );
      
      if (response.statusCode == 200) {
        Logger.info('✅ Notification sent successfully');
        return true;
      } else {
        Logger.info('❌ Failed to send notification: ${response.body}');
        return false;
      }
    } catch (e) {
      Logger.info('❌ Send notification error: $e');
      return false;
    }
  }
  
  // Send to multiple tokens
  Future<void> sendToMultipleTokens({
    required List<String> fcmTokens,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    for (final token in fcmTokens) {
      await sendNotification(
        fcmToken: token,
        title: title,
        body: body,
        data: data,
      );
      
      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}