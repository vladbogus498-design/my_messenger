import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Получить данные пользователя
  static Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return UserModel(
          uid: userId,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          photoURL: data['photoURL'],
          bio: data['bio'],
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // Обновить данные пользователя
  static Future<void> updateUserData({
    String? name,
    String? bio,
    String? photoURL,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (photoURL != null) updates['photoURL'] = photoURL;

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      print('❌ Error updating user data: $e');
      throw e;
    }
  }

  // Поиск пользователей по тэгу/имени
  static Future<List<UserModel>> searchUsersByTag(String tag) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: tag)
          .where('name', isLessThan: tag + '\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          uid: doc.id,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          photoURL: data['photoURL'],
          bio: data['bio'],
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }

  // Создать/обновить профиль пользователя при регистрации
  static Future<void> createUserProfile(
      String uid, String email, String name) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error creating user profile: $e');
      throw e;
    }
  }

  static Future<void> ensureUserProfile({
    required User user,
    String? fallbackName,
  }) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) return;

      final email = user.email ?? '';
      final phone = user.phoneNumber ?? '';
      final generatedName = user.displayName ??
          fallbackName ??
          (email.isNotEmpty
              ? email.split('@').first
              : phone.isNotEmpty
                  ? phone
                  : 'Пользователь');

      await docRef.set({
        'uid': user.uid,
        'email': email,
        'phone': phone,
        'name': generatedName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error ensuring user profile: $e');
    }
  }
}