import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? profilePicture;
  final String? spotifyId;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime lastActive;
  final List<String> playlistIds;
  final Map<String, dynamic>? spotifyData;
  
  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.profilePicture,
    this.spotifyId,
    this.fcmToken,
    required this.createdAt,
    required this.lastActive,
    this.playlistIds = const [],
    this.spotifyData,
  });
  
  // Create from Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    try {
      // Safely get data - handle both Map and other types
      final rawData = doc.data();
      Map<String, dynamic>? data;
      
      if (rawData == null) {
        throw Exception('Document data is null');
      }
      
      // Safely cast to Map
      if (rawData is Map) {
        data = Map<String, dynamic>.from(rawData);
      } else {
        Logger.error('Unexpected data type in Firestore document', 
            Exception('Expected Map but got ${rawData.runtimeType}'), null);
        throw Exception('Invalid document data type: ${rawData.runtimeType}');
      }
      
      // Safely convert playlistIds to List<String>
      List<String> playlistIds = [];
      final playlistIdsData = data['playlistIds'];
      if (playlistIdsData != null) {
        if (playlistIdsData is List) {
          playlistIds = playlistIdsData
              .where((item) => item != null)
              .map((item) => item.toString())
              .toList();
        } else {
          Logger.warning('playlistIds is not a List, got ${playlistIdsData.runtimeType}');
        }
      }
      
      // Safely get spotifyData
      Map<String, dynamic>? spotifyData;
      final spotifyDataRaw = data['spotifyData'];
      if (spotifyDataRaw != null) {
        if (spotifyDataRaw is Map) {
          spotifyData = Map<String, dynamic>.from(spotifyDataRaw);
        } else {
          Logger.warning('spotifyData is not a Map, got ${spotifyDataRaw.runtimeType}');
        }
      }
      
      // Safely get string fields
      String? getStringField(Map<String, dynamic> dataMap, String key) {
        final value = dataMap[key];
        if (value == null) return null;
        if (value is String) return value;
        return value.toString();
      }
      
      // Safely get Timestamp fields
      DateTime? getDateTimeField(Map<String, dynamic> dataMap, String key) {
        final value = dataMap[key];
        if (value == null) return null;
        if (value is Timestamp) return value.toDate();
        if (value is DateTime) return value;
        return null;
      }
      
      // Use data directly (we already checked it's not null above)
      final dataMap = data;
      
      return UserModel(
        uid: doc.id,
        email: getStringField(dataMap, 'email') ?? '',
        displayName: getStringField(dataMap, 'displayName') ?? 'User',
        profilePicture: getStringField(dataMap, 'profilePicture'),
        spotifyId: getStringField(dataMap, 'spotifyId'),
        fcmToken: getStringField(dataMap, 'fcmToken'),
        createdAt: getDateTimeField(dataMap, 'createdAt') ?? DateTime.now(),
        lastActive: getDateTimeField(dataMap, 'lastActive') ?? DateTime.now(),
        playlistIds: playlistIds,
        spotifyData: spotifyData,
      );
    } catch (e, st) {
      Logger.error('Error parsing UserModel from Firestore', e, st);
      Logger.error('Document ID: ${doc.id}', null, null);
      Logger.error('Document exists: ${doc.exists}', null, null);
      if (doc.exists) {
        Logger.error('Raw data type: ${doc.data().runtimeType}', null, null);
      }
      rethrow;
    }
  }
  
  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'profilePicture': profilePicture,
      'spotifyId': spotifyId,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'playlistIds': playlistIds,
      'spotifyData': spotifyData,
    };
  }
  
  // Copy with
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? profilePicture,
    String? spotifyId,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? lastActive,
    List<String>? playlistIds,
    Map<String, dynamic>? spotifyData,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profilePicture: profilePicture ?? this.profilePicture,
      spotifyId: spotifyId ?? this.spotifyId,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      playlistIds: playlistIds ?? this.playlistIds,
      spotifyData: spotifyData ?? this.spotifyData,
    );
  }
  
  // Get initials
  String get initials {
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return displayName.substring(0, 2).toUpperCase();
  }
}