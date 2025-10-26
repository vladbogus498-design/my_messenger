class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoURL;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoURL,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoURL: data['photoURL'],
      createdAt:
          data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoURL': photoURL,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
