import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../utils/input_validator.dart';
import '../utils/logger.dart';
import '../utils/rate_limiter.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<UserModel?> watchUserData(String userId) {
    if (!InputValidator.isValidUserId(userId)) {
      return const Stream<UserModel?>.empty();
    }

    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  static Future<UserModel?> getUserData(String userId) async {
    try {
      if (!InputValidator.isValidUserId(userId)) {
        appLogger.w('Invalid userId in getUserData');
        return null;
      }

      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      appLogger.e('Error getting user data for userId: $userId', error: e);
      return null;
    }
  }

  static Future<void> setPresence({required bool isOnline}) async {
    final user = _auth.currentUser;
    if (user == null || !InputValidator.isValidUserId(user.uid)) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': (user.email ?? '').toLowerCase().trim(),
        'emailLower': (user.email ?? '').toLowerCase().trim(),
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      appLogger.e('Error updating user presence', error: e);
    }
  }

  static Future<void> updateUserData({
    String? name,
    String? bio,
    String? photoURL,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final updates = <String, dynamic>{};
      if (name != null) {
        final nameError = InputValidator.validateName(name);
        if (nameError != null) throw Exception(nameError);
        final sanitizedName = InputValidator.sanitizeName(name);
        updates['name'] = sanitizedName;
        updates['nameLower'] = sanitizedName.toLowerCase();
      }
      if (bio != null) {
        final bioError = InputValidator.validateBio(bio);
        if (bioError != null) throw Exception(bioError);
        updates['bio'] = InputValidator.sanitizeBio(bio);
      }
      if (photoURL != null) {
        final uri = Uri.tryParse(photoURL);
        if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
          throw Exception('Invalid photoURL format');
        }
        updates['photoURL'] = photoURL;
        updates['avatarUpdatedAt'] = FieldValue.serverTimestamp();
      }

      if (updates.isEmpty) return;
      await _firestore
          .collection('users')
          .doc(userId)
          .set(updates, SetOptions(merge: true));
      if (photoURL != null) {
        try {
          await _auth.currentUser?.updatePhotoURL(photoURL);
        } catch (e) {
          appLogger.e('Error updating FirebaseAuth photoURL', error: e);
        }
      }
      appLogger.d('User data updated for userId: $userId');
    } catch (e) {
      appLogger.e('Error updating user data for userId: $userId', error: e);
      rethrow;
    }
  }

  static Future<List<UserModel>> searchUsersByTag(String tag) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      if (!AppRateLimiters.searchLimiter.tryRequest('search_users_$userId')) {
        appLogger.w('Search rate limit exceeded for user: $userId');
        return [];
      }

      final sanitizedTag = InputValidator.sanitizeSearchQuery(
        tag,
      ).toLowerCase();
      if (sanitizedTag.isEmpty) return [];

      final snapshot = await _firestore
          .collection('users')
          .where('nameLower', isGreaterThanOrEqualTo: sanitizedTag)
          .where('nameLower', isLessThan: '$sanitizedTag\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs.map(UserModel.fromFirestore).toList();
    } catch (e) {
      appLogger.e('Error searching users by tag: $tag', error: e);
      return [];
    }
  }

  static Future<void> createUserProfile(
    String uid,
    String email,
    String name,
  ) async {
    try {
      if (!InputValidator.isValidUserId(uid)) throw Exception('Invalid userId');

      final emailError = InputValidator.validateEmail(email);
      if (emailError != null) throw Exception(emailError);

      final nameError = InputValidator.validateName(name);
      if (nameError != null) throw Exception(nameError);

      final sanitizedName = InputValidator.sanitizeName(name);

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email.toLowerCase().trim(),
        'name': sanitizedName,
        'nameLower': sanitizedName.toLowerCase(),
        'emailLower': email.toLowerCase().trim(),
        'bio': '',
        'photoURL': null,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      appLogger.i('User profile created: uid=$uid');
    } catch (e) {
      appLogger.e('Error creating user profile: uid=$uid', error: e);
      rethrow;
    }
  }

  static Future<void> ensureUserProfile({
    required User user,
    String? fallbackName,
  }) async {
    try {
      if (!InputValidator.isValidUserId(user.uid)) {
        appLogger.e('Invalid userId in ensureUserProfile');
        return;
      }

      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.set({
          'uid': user.uid,
          if (user.email != null) 'email': user.email!.toLowerCase().trim(),
          if (user.email != null)
            'emailLower': user.email!.toLowerCase().trim(),
          if (user.photoURL != null) 'photoURL': user.photoURL,
        }, SetOptions(merge: true));
        return;
      }

      final email = user.email ?? '';
      final phone = user.phoneNumber ?? '';
      final generatedName =
          user.displayName ??
          fallbackName ??
          (email.isNotEmpty
              ? email.split('@').first
              : phone.isNotEmpty
              ? phone
              : 'Пользователь');
      final sanitizedName = InputValidator.sanitizeName(generatedName);

      await docRef.set({
        'uid': user.uid,
        'email': email.toLowerCase().trim(),
        'emailLower': email.toLowerCase().trim(),
        'phone': phone.trim(),
        'name': sanitizedName,
        'nameLower': sanitizedName.toLowerCase(),
        'bio': '',
        'photoURL': user.photoURL,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      appLogger.d('User profile ensured for uid: ${user.uid}');
    } catch (e) {
      appLogger.e('Error ensuring user profile for uid: ${user.uid}', error: e);
    }
  }
}
