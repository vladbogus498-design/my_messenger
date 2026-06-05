import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../utils/input_validator.dart';
import '../utils/logger.dart';
import '../utils/rate_limiter.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static Future<void> _presenceWriteQueue = Future.value();
  static int _presenceRequestId = 0;

  static Stream<UserModel?> watchUserData(String userId) {
    if (!InputValidator.isValidUserId(userId)) {
      return const Stream<UserModel?>.empty();
    }

    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  static Stream<UserModel?> watchPublicUserData(String userId) {
    if (!InputValidator.isValidUserId(userId)) {
      return const Stream<UserModel?>.empty();
    }

    return _firestore.collection('publicProfiles').doc(userId).snapshots().map((
      doc,
    ) {
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

  static Future<UserModel?> getPublicUserData(String userId) async {
    try {
      if (!InputValidator.isValidUserId(userId)) {
        appLogger.w('Invalid userId in getPublicUserData');
        return null;
      }

      final doc = await _firestore
          .collection('publicProfiles')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      appLogger.e(
        'Error getting public user data for userId: $userId',
        error: e,
      );
      return null;
    }
  }

  static Future<void> setPresence({
    required bool isOnline,
    bool force = false,
  }) {
    final user = _auth.currentUser;
    if (user == null || !InputValidator.isValidUserId(user.uid)) {
      return Future.value();
    }

    final requestId = ++_presenceRequestId;
    final userId = user.uid;
    final email = user.email;
    final displayName = user.displayName;

    _presenceWriteQueue = _presenceWriteQueue
        .catchError((Object e, StackTrace s) {
          appLogger.e('Previous presence update failed', error: e);
        })
        .then((_) {
          if (!force && requestId != _presenceRequestId) {
            return Future<void>.value();
          }
          return _setPresenceNow(
            userId: userId,
            email: email,
            displayName: displayName,
            isOnline: isOnline,
          );
        });

    return _presenceWriteQueue;
  }

  static Future<void> _setPresenceNow({
    required String userId,
    required String? email,
    required String? displayName,
    required bool isOnline,
  }) async {
    try {
      final userUpdates = <String, dynamic>{
        'uid': userId,
        'email': (email ?? '').toLowerCase().trim(),
        'emailLower': (email ?? '').toLowerCase().trim(),
        'isOnline': isOnline,
        if (!isOnline) 'lastSeen': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('users')
          .doc(userId)
          .set(userUpdates, SetOptions(merge: true));
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? const <String, dynamic>{};
      final existingName = (userData['name'] ?? '').toString().trim();
      await _upsertPublicProfile(userId, {
        ...userData,
        'uid': userId,
        'name': existingName.isNotEmpty
            ? existingName
            : displayName ?? (email?.split('@').first ?? 'Пользователь'),
        'isOnline': isOnline,
        if (!isOnline) 'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      appLogger.e('Error updating user presence', error: e);
    }
  }

  static Future<void> updateUserData({
    String? name,
    String? bio,
    String? photoURL,
    String? tag,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final updates = <String, dynamic>{};
      final userRef = _firestore.collection('users').doc(userId);
      final currentDoc = await userRef.get();
      final currentData = currentDoc.data() ?? const <String, dynamic>{};
      final authUser = _auth.currentUser;
      var nextName =
          (currentData['name'] ??
                  authUser?.displayName ??
                  authUser?.email?.split('@').first ??
                  '')
              .toString();
      var nextTag = (currentData['tag'] ?? currentData['username'] ?? '')
          .toString();
      var nextUsername = (currentData['username'] ?? currentData['tag'] ?? '')
          .toString();

      if (name != null) {
        final nameError = _validateProfileName(name);
        if (nameError != null) throw Exception(nameError);
        final sanitizedName = _sanitizeProfileName(name);
        updates['name'] = sanitizedName;
        updates['nameLower'] = sanitizedName.toLowerCase();
        nextName = sanitizedName;
      }
      if (bio != null) {
        final bioError = InputValidator.validateBio(bio);
        if (bioError != null) throw Exception(bioError);
        updates['bio'] = InputValidator.sanitizeBio(bio);
      }
      if (tag != null) {
        final sanitizedTag = _sanitizeTag(tag);
        updates['tag'] = sanitizedTag;
        updates['tagLower'] = sanitizedTag.toLowerCase();
        updates['username'] = sanitizedTag;
        updates['usernameLower'] = sanitizedTag.toLowerCase();
        nextTag = sanitizedTag;
        nextUsername = sanitizedTag;
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
      updates['searchKeywords'] = _buildSearchKeywords(
        nextName,
        nextTag,
        nextUsername,
      );
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await userRef.set(updates, SetOptions(merge: true));
      final freshDoc = await userRef.get();
      await _upsertPublicProfile(userId, freshDoc.data() ?? updates);
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

  static Future<void> ensurePublicProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null || !InputValidator.isValidUserId(user.uid)) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        await _upsertPublicProfile(user.uid, userDoc.data() ?? const {});
        return;
      }

      await ensureUserProfile(
        user: user,
        fallbackName: user.email?.split('@').first ?? user.phoneNumber,
      );
    } catch (e) {
      appLogger.e('Error ensuring public profile', error: e);
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

      final byName = await _firestore
          .collection('publicProfiles')
          .where('nameLower', isGreaterThanOrEqualTo: sanitizedTag)
          .where('nameLower', isLessThan: '$sanitizedTag\uf8ff')
          .limit(20)
          .get();
      final byTag = await _firestore
          .collection('publicProfiles')
          .where('tagLower', isGreaterThanOrEqualTo: sanitizedTag)
          .where('tagLower', isLessThan: '$sanitizedTag\uf8ff')
          .limit(20)
          .get();
      final byKeyword = await _firestore
          .collection('publicProfiles')
          .where('searchKeywords', arrayContains: sanitizedTag)
          .limit(20)
          .get();

      final seen = <String>{};
      return [
        ...byName.docs,
        ...byTag.docs,
        ...byKeyword.docs,
      ].where((doc) => seen.add(doc.id)).map(UserModel.fromFirestore).toList();
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

      final nameError = _validateProfileName(name);
      if (nameError != null) throw Exception(nameError);

      final sanitizedName = _sanitizeProfileName(name);
      final searchKeywords = _buildSearchKeywords(sanitizedName, '', '');

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email.toLowerCase().trim(),
        'name': sanitizedName,
        'nameLower': sanitizedName.toLowerCase(),
        'searchKeywords': searchKeywords,
        'emailLower': email.toLowerCase().trim(),
        'bio': '',
        'photoURL': null,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _upsertPublicProfile(uid, {
        'uid': uid,
        'name': sanitizedName,
        'nameLower': sanitizedName.toLowerCase(),
        'bio': '',
        'photoURL': null,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
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
        final data = doc.data() ?? const <String, dynamic>{};
        final existingName = (data['name'] ?? user.displayName ?? fallbackName)
            ?.toString()
            .trim();
        final nameForSearch = (existingName == null || existingName.isEmpty)
            ? (user.email?.split('@').first ?? user.phoneNumber ?? 'Пользователь')
            : existingName;
        final tagForSearch = (data['tag'] ?? data['username'] ?? '')
            .toString()
            .trim();
        final usernameForSearch = (data['username'] ?? data['tag'] ?? '')
            .toString()
            .trim();
        final updates = {
          'uid': user.uid,
          if (user.email != null) 'email': user.email!.toLowerCase().trim(),
          if (user.email != null)
            'emailLower': user.email!.toLowerCase().trim(),
          if (user.photoURL != null) 'photoURL': user.photoURL,
          'nameLower': nameForSearch.toLowerCase(),
          'searchKeywords': _buildSearchKeywords(
            nameForSearch,
            tagForSearch,
            usernameForSearch,
          ),
        };
        await docRef.set({...updates}, SetOptions(merge: true));
        await _upsertPublicProfile(user.uid, {...data, ...updates});
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
      final sanitizedName = _sanitizeProfileName(generatedName);
      final searchKeywords = _buildSearchKeywords(sanitizedName, '', '');

      await docRef.set({
        'uid': user.uid,
        'email': email.toLowerCase().trim(),
        'emailLower': email.toLowerCase().trim(),
        'phone': phone.trim(),
        'name': sanitizedName,
        'nameLower': sanitizedName.toLowerCase(),
        'searchKeywords': searchKeywords,
        'bio': '',
        'photoURL': user.photoURL,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _upsertPublicProfile(user.uid, {
        'uid': user.uid,
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

  static Future<void> _upsertPublicProfile(
    String uid,
    Map<String, dynamic> source,
  ) async {
    final rawName = (source['name'] ?? 'Пользователь').toString().trim();
    final name = rawName.isEmpty ? 'Пользователь' : rawName;
    final tag = (source['tag'] ?? source['username'] ?? '').toString().trim();
    final username = (source['username'] ?? source['tag'] ?? '')
        .toString()
        .trim();
    final publicData = <String, dynamic>{
      'uid': uid,
      'name': name,
      'nameLower': name.toLowerCase(),
      'searchKeywords': _buildSearchKeywords(name, tag, username),
      'updatedAt': FieldValue.serverTimestamp(),
      if (source['username'] != null) 'username': source['username'],
      if (source['username'] != null)
        'usernameLower': source['username'].toString().toLowerCase(),
      if (source['tag'] != null) 'tag': source['tag'],
      if (source['tag'] != null)
        'tagLower': source['tag'].toString().toLowerCase(),
      if (source.containsKey('bio')) 'bio': source['bio'] ?? '',
      if (source.containsKey('photoURL')) 'photoURL': source['photoURL'],
      if (source.containsKey('avatarUpdatedAt'))
        'avatarUpdatedAt': source['avatarUpdatedAt'],
      if (source.containsKey('publicKey')) 'publicKey': source['publicKey'],
      if (source.containsKey('publicKeyUpdatedAt'))
        'publicKeyUpdatedAt': source['publicKeyUpdatedAt'],
      if (source.containsKey('isOnline'))
        'isOnline': source['isOnline'] == true,
      if (source.containsKey('lastSeen')) 'lastSeen': source['lastSeen'],
      if (source.containsKey('createdAt')) 'createdAt': source['createdAt'],
    };

    await _firestore
        .collection('publicProfiles')
        .doc(uid)
        .set(publicData, SetOptions(merge: true));
  }

  static String _sanitizeTag(String rawTag) {
    final tag = rawTag.trim().replaceFirst(RegExp(r'^@+'), '');
    final sanitized = tag
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '')
        .toLowerCase();
    return sanitized.length > 32 ? sanitized.substring(0, 32) : sanitized;
  }

  static String? _validateProfileName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Имя не может быть пустым';
    }

    final trimmed = name.trim();
    if (trimmed.length > InputValidator.maxNameLength) {
      return 'Имя слишком длинное';
    }

    if (!RegExp(
      r'^[a-zA-Zа-яА-ЯёЁ0-9\s\-_\.]+$',
      unicode: true,
    ).hasMatch(trimmed)) {
      return 'Имя содержит недопустимые символы';
    }

    return null;
  }

  static String _sanitizeProfileName(String name) {
    var sanitized = name.replaceAll(
      RegExp(r'[^a-zA-Zа-яА-ЯёЁ0-9\s\-_\.]', unicode: true),
      '',
    );
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (sanitized.length > InputValidator.maxNameLength) {
      sanitized = sanitized.substring(0, InputValidator.maxNameLength).trim();
    }
    return sanitized;
  }

  static List<String> _buildSearchKeywords(
    String name,
    String tag,
    String username,
  ) {
    final values = <String>{};

    void addValue(String raw) {
      final value = raw.trim().toLowerCase();
      if (value.isEmpty) return;
      values.add(value);
      for (final part in value.split(RegExp(r'[\s@._-]+'))) {
        if (part.isEmpty) continue;
        values.add(part);
        final maxLength = part.length > 24 ? 24 : part.length;
        for (var i = 1; i <= maxLength; i++) {
          values.add(part.substring(0, i));
        }
      }
      final compact = value.replaceAll(RegExp(r'[\s@._-]+'), '');
      if (compact.isNotEmpty) values.add(compact);
    }

    addValue(name);
    addValue(tag);
    addValue(username);

    return values.take(80).toList();
  }
}
