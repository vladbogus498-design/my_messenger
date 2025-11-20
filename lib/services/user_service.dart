import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';
import '../utils/input_validator.dart';
import '../utils/rate_limiter.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Получить данные пользователя
  static Future<UserModel?> getUserData(String userId) async {
    try {
      // Валидация userId
      if (!InputValidator.isValidUserId(userId)) {
        appLogger.w('Invalid userId in getUserData');
        return null;
      }

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
      appLogger.e('Error getting user data for userId: $userId', error: e);
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
      // Валидация и санитизация входных данных
      final updates = <String, dynamic>{};
      if (name != null) {
        final nameError = InputValidator.validateName(name);
        if (nameError != null) {
          throw Exception(nameError);
        }
        updates['name'] = InputValidator.sanitizeName(name);
      }
      if (bio != null) {
        final bioError = InputValidator.validateBio(bio);
        if (bioError != null) {
          throw Exception(bioError);
        }
        updates['bio'] = InputValidator.sanitizeBio(bio);
      }
      if (photoURL != null) {
        // Валидация URL
        if (!Uri.tryParse(photoURL)?.hasAbsolutePath ?? false) {
          throw Exception('Invalid photoURL format');
        }
        updates['photoURL'] = photoURL;
      }

      await _firestore.collection('users').doc(userId).update(updates);
      appLogger.d('User data updated for userId: $userId');
    } catch (e) {
      appLogger.e('Error updating user data for userId: $userId', error: e);
      throw e;
    }
  }

  // Поиск пользователей по тэгу/имени
  static Future<List<UserModel>> searchUsersByTag(String tag) async {
    try {
      // Rate limiting: проверка лимита на поиск
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      if (!AppRateLimiters.searchLimiter.tryRequest('search_users_$userId')) {
        appLogger.w('Search rate limit exceeded for user: $userId');
        return [];
      }

      // Санитизация поискового запроса (защита от NoSQL injection)
      final sanitizedTag = InputValidator.sanitizeSearchQuery(tag);
      if (sanitizedTag.isEmpty) {
        return [];
      }

      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: sanitizedTag)
          .where('name', isLessThan: sanitizedTag + '\uf8ff')
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
      appLogger.e('Error searching users by tag: $tag', error: e);
      return [];
    }
  }

  // Создать/обновить профиль пользователя при регистрации
  static Future<void> createUserProfile(
      String uid, String email, String name) async {
    try {
      // Валидация входных данных
      if (!InputValidator.isValidUserId(uid)) {
        throw Exception('Invalid userId');
      }
      
      final emailError = InputValidator.validateEmail(email);
      if (emailError != null) {
        throw Exception(emailError);
      }

      final nameError = InputValidator.validateName(name);
      if (nameError != null) {
        throw Exception(nameError);
      }

      final sanitizedName = InputValidator.sanitizeName(name);

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email.toLowerCase().trim(),
        'name': sanitizedName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Не логируем email в открытом виде (безопасность)
      appLogger.i('User profile created: uid=$uid');
    } catch (e) {
      appLogger.e('Error creating user profile: uid=$uid', error: e);
      throw e;
    }
  }

  static Future<void> ensureUserProfile({
    required User user,
    String? fallbackName,
  }) async {
    try {
      // Валидация userId
      if (!InputValidator.isValidUserId(user.uid)) {
        appLogger.e('Invalid userId in ensureUserProfile');
        return;
      }

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

      // Санитизация имени
      final sanitizedName = InputValidator.sanitizeName(generatedName);

      await docRef.set({
        'uid': user.uid,
        'email': email.toLowerCase().trim(),
        'phone': phone.trim(),
        'name': sanitizedName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      appLogger.d('User profile ensured for uid: ${user.uid}');
    } catch (e) {
      appLogger.e('Error ensuring user profile for uid: ${user.uid}', error: e);
    }
  }
}