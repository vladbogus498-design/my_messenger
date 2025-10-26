import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String email;
  final String username;
  final String avatarUrl;
  final Timestamp createdAt;
  final bool isOnline;
  final Timestamp lastSeen;
  final String? typingStatus;
  final String bio;

  UserProfile({
    required this.userId,
    required this.email,
    required this.username,
    required this.avatarUrl,
    required this.createdAt,
    required this.isOnline,
    required this.lastSeen,
    this.typingStatus,
    this.bio = '',
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      userId: data['userId'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'] ?? Timestamp.now(),
      typingStatus: data['typingStatus'],
      bio: data['bio'] ?? '',
    );
  }
}
