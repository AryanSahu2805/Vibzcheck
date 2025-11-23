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
      final data = doc.data() as Map<String, dynamic>?;
      
      if (data == null) {
        throw Exception('Document data is null');
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
        }
      }
      
      return UserModel(
        uid: doc.id,
        email: data['email'] ?? '',
        displayName: data['displayName'] ?? 'User',
        profilePicture: data['profilePicture'] as String?,
        spotifyId: data['spotifyId'] as String?,
        fcmToken: data['fcmToken'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastActive: (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
        playlistIds: playlistIds,
        spotifyData: data['spotifyData'] as Map<String, dynamic>?,
      );
    } catch (e, st) {
      Logger.error('Error parsing UserModel from Firestore', e, st);
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