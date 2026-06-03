import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoURL,
    this.bio,
    this.tag,
    this.username,
    this.premiumStatus = false,
    this.createdAt,
    this.isOnline = false,
    this.lastSeen,
  });

  final String uid;
  final String email;
  final String name;
  final String? photoURL;
  final String? bio;
  final String? tag;
  final String? username;
  final bool premiumStatus;
  final DateTime? createdAt;
  final bool isOnline;
  final DateTime? lastSeen;

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: (data['uid'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      photoURL: data['photoURL']?.toString(),
      bio: data['bio']?.toString(),
      tag: data['tag']?.toString(),
      username: data['username']?.toString(),
      premiumStatus: data['premiumStatus'] == true,
      createdAt: _readDate(data['createdAt']),
      isOnline: data['isOnline'] == true,
      lastSeen: _readDate(data['lastSeen']),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserModel.fromMap({...?doc.data(), 'uid': doc.id});
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoURL': photoURL,
      'bio': bio,
      'tag': tag,
      'username': username,
      'premiumStatus': premiumStatus,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'isOnline': isOnline,
      'lastSeen': lastSeen == null ? null : Timestamp.fromDate(lastSeen!),
    };
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
