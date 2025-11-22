import 'package:cloud_firestore/cloud_firestore.dart';

class PlaylistModel {
  final String id;
  final String name;
  final String? description;
  final String? coverImage;
  final String creatorId;
  final String creatorName;
  final List<ParticipantModel> participants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String shareCode;
  final bool isPublic;
  final int songCount;
  
  PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    this.coverImage,
    required this.creatorId,
    required this.creatorName,
    this.participants = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.shareCode,
    this.isPublic = false,
    this.songCount = 0,
  });
  
  factory PlaylistModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PlaylistModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      coverImage: data['coverImage'],
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      participants: (data['participants'] as List?)
          ?.map((p) => ParticipantModel.fromMap(p as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shareCode: data['shareCode'] ?? '',
      isPublic: data['isPublic'] ?? false,
      songCount: data['songCount'] ?? 0,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'coverImage': coverImage,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'participants': participants.map((p) => p.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'shareCode': shareCode,
      'isPublic': isPublic,
      'songCount': songCount,
    };
  }
  
  PlaylistModel copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImage,
    String? creatorId,
    String? creatorName,
    List<ParticipantModel>? participants,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? shareCode,
    bool? isPublic,
    int? songCount,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shareCode: shareCode ?? this.shareCode,
      isPublic: isPublic ?? this.isPublic,
      songCount: songCount ?? this.songCount,
    );
  }
}

class ParticipantModel {
  final String userId;
  final String displayName;
  final String? profilePicture;
  final DateTime joinedAt;
  final String role; // 'creator', 'member'
  
  ParticipantModel({
    required this.userId,
    required this.displayName,
    this.profilePicture,
    required this.joinedAt,
    this.role = 'member',
  });
  
  factory ParticipantModel.fromMap(Map<String, dynamic> map) {
    return ParticipantModel(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      profilePicture: map['profilePicture'],
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: map['role'] ?? 'member',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'profilePicture': profilePicture,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'role': role,
    };
  }
}