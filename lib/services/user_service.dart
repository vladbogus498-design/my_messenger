import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../utils/input_validator.dart';
import '../utils/logger.dart';
import '../utils/rate_limiter.dart';

class UsernameTakenException implements Exception {
  const UsernameTakenException();

  @override
  String toString() => 'Username уже занят';
}

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static Future<void> _presenceWriteQueue = Future.value();
  static int _presenceRequestId = 0;
  static const Set<String> _localRulesUserFields = {
    'uid',
    'email',
    'emailLower',
    'phone',
    'name',
    'nameLower',
    'username',
    'usernameLower',
    'tag',
    'tagLower',
    'searchKeywords',
    'bio',
    'photoURL',
    'avatarUpdatedAt',
    'publicKey',
    'publicKeyUpdatedAt',
    'isOnline',
    'lastSeen',
    'createdAt',
    'updatedAt',
    'premiumStatus',
  };
  static const Set<String> _localRulesPublicProfileFields = {
    'uid',
    'name',
    'nameLower',
    'username',
    'usernameLower',
    'tag',
    'tagLower',
    'searchKeywords',
    'bio',
    'photoURL',
    'avatarUpdatedAt',
    'publicKey',
    'publicKeyUpdatedAt',
    'isOnline',
    'lastSeen',
    'createdAt',
    'updatedAt',
  };

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
    if (userId == null) throw Exception('User not authenticated');

    try {
      appLogger.d('Profile save started: userId=$userId');
      final updates = <String, dynamic>{};
      final userRef = _firestore.collection('users').doc(userId);
      final publicProfileRef = _firestore
          .collection('publicProfiles')
          .doc(userId);
      appLogger.d('Users document read started: users/$userId');
      var currentDoc = await userRef.get();
      appLogger.d(
        'Users document read success: users/$userId exists=${currentDoc.exists}',
      );
      if (!currentDoc.exists) {
        appLogger.w(
          'Users document missing before profile save: users/$userId. '
          'Creating automatically.',
        );
        final user = _auth.currentUser;
        if (user == null) throw Exception('User not authenticated');
        await ensureUserProfile(
          user: user,
          fallbackName: user.email?.split('@').first ?? user.phoneNumber,
        );
        currentDoc = await userRef.get();
        appLogger.d(
          'Users document reread after auto-create: users/$userId '
          'exists=${currentDoc.exists}',
        );
      }
      final currentData = currentDoc.data() ?? const <String, dynamic>{};
      final currentUsernameLower =
          (currentData['usernameLower'] ?? currentData['tagLower'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
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

      appLogger.d(
        'UserService.updateUserData before save: userId=$userId '
        'fields=${updates.keys.toList()} name="$nextName" tag="$nextTag" '
        'username="$nextUsername" bioChanged=${bio != null} '
        'photoChanged=${photoURL != null}',
      );

      final mergedData = <String, dynamic>{...currentData, ...updates};
      final publicData = _publicProfileData(userId, mergedData);
      _logUnexpectedProfileFields(
        documentPath: 'users/$userId',
        fields: updates.keys,
        allowedFields: _localRulesUserFields,
      );
      _logUnexpectedProfileFields(
        documentPath: 'publicProfiles/$userId',
        fields: publicData.keys,
        allowedFields: _localRulesPublicProfileFields,
      );
      if (tag != null) {
        await _saveProfileWithUsernameTransaction(
          userId: userId,
          updates: updates,
          publicData: publicData,
          userRef: userRef,
          publicProfileRef: publicProfileRef,
          currentUsernameLower: currentUsernameLower,
          nextUsernameLower: updates['usernameLower']?.toString() ?? '',
          nextUsername: updates['username']?.toString() ?? '',
        );
      } else {
        appLogger.d(
          'Users document update started: users/$userId set(merge) '
          'fields=${updates.keys.toList()}',
        );
        try {
          await userRef.set(updates, SetOptions(merge: true));
          appLogger.d('Users document update success: users/$userId');
        } on FirebaseException catch (e) {
          appLogger.e(
            'Users document update failed: users/$userId '
            '${e.code} ${e.message ?? ''}',
            error: e,
          );
          rethrow;
        }

        appLogger.d(
          'PublicProfiles update started: publicProfiles/$userId set '
          'fields=${publicData.keys.toList()}',
        );
        try {
          await publicProfileRef.set(publicData);
          appLogger.d('PublicProfiles update success: publicProfiles/$userId');
        } on FirebaseException catch (e) {
          appLogger.e(
            'PublicProfiles update failed: publicProfiles/$userId '
            '${e.code} ${e.message ?? ''}',
            error: e,
          );
          rethrow;
        }
      }

      if (photoURL != null) {
        try {
          await _auth.currentUser?.updatePhotoURL(photoURL);
        } catch (e) {
          appLogger.e('Error updating FirebaseAuth photoURL', error: e);
        }
      }
      appLogger.d(
        'UserService.updateUserData success: userId=$userId '
        'publicFields=${publicData.keys.toList()}',
      );
    } on FirebaseException catch (e) {
      appLogger.e(
        'UserService.updateUserData FirebaseException: '
        '${e.code} ${e.message ?? ''}',
        error: e,
      );
      rethrow;
    } catch (e) {
      appLogger.e('Error updating user data for userId: $userId', error: e);
      rethrow;
    }
  }

  static Future<void> _saveProfileWithUsernameTransaction({
    required String userId,
    required Map<String, dynamic> updates,
    required Map<String, dynamic> publicData,
    required DocumentReference<Map<String, dynamic>> userRef,
    required DocumentReference<Map<String, dynamic>> publicProfileRef,
    required String currentUsernameLower,
    required String nextUsernameLower,
    required String nextUsername,
  }) async {
    final usernames = _firestore.collection('usernames');
    final nextUsernameRef = nextUsernameLower.isEmpty
        ? null
        : usernames.doc(nextUsernameLower);
    final oldUsernameRef =
        currentUsernameLower.isEmpty ||
            currentUsernameLower == nextUsernameLower
        ? null
        : usernames.doc(currentUsernameLower);

    appLogger.d(
      'Profile username transaction started: userId=$userId '
      'oldUsernameLower="$currentUsernameLower" '
      'nextUsernameLower="$nextUsernameLower"',
    );

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot<Map<String, dynamic>>? nextUsernameDoc;
        DocumentSnapshot<Map<String, dynamic>>? oldUsernameDoc;

        if (nextUsernameRef != null) {
          nextUsernameDoc = await transaction.get(nextUsernameRef);
          final ownerUid = nextUsernameDoc.data()?['uid']?.toString();
          if (nextUsernameDoc.exists && ownerUid != userId) {
            appLogger.w(
              'Username is already taken: usernameLower=$nextUsernameLower '
              'ownerUid=$ownerUid currentUid=$userId',
            );
            throw const UsernameTakenException();
          }
        }

        if (oldUsernameRef != null) {
          oldUsernameDoc = await transaction.get(oldUsernameRef);
        }

        appLogger.d(
          'Users document update started: users/$userId transaction set(merge) '
          'fields=${updates.keys.toList()}',
        );
        transaction.set(userRef, updates, SetOptions(merge: true));

        appLogger.d(
          'PublicProfiles update started: publicProfiles/$userId '
          'transaction set fields=${publicData.keys.toList()}',
        );
        transaction.set(publicProfileRef, publicData);

        if (oldUsernameRef != null &&
            oldUsernameDoc?.exists == true &&
            oldUsernameDoc?.data()?['uid']?.toString() == userId) {
          transaction.delete(oldUsernameRef);
        }

        if (nextUsernameRef != null) {
          transaction.set(nextUsernameRef, {
            'uid': userId,
            'username': nextUsername,
            'usernameLower': nextUsernameLower,
            if (nextUsernameDoc?.exists != true)
              'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });
      appLogger.d(
        'Profile username transaction success: userId=$userId '
        'usernameLower="$nextUsernameLower"',
      );
    } on UsernameTakenException {
      rethrow;
    } on FirebaseException catch (e) {
      appLogger.e(
        'Profile username transaction failed: '
        '${e.code} ${e.message ?? ''}',
        error: e,
      );
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
    final publicData = _publicProfileData(uid, source);
    _logUnexpectedProfileFields(
      documentPath: 'publicProfiles/$uid',
      fields: publicData.keys,
      allowedFields: _localRulesPublicProfileFields,
    );

    appLogger.d(
      'PublicProfiles update started: publicProfiles/$uid set '
      'fields=${publicData.keys.toList()}',
    );
    await _firestore
        .collection('publicProfiles')
        .doc(uid)
        .set(publicData);
    appLogger.d('PublicProfiles update success: publicProfiles/$uid');
  }

  static void _logUnexpectedProfileFields({
    required String documentPath,
    required Iterable<String> fields,
    required Set<String> allowedFields,
  }) {
    final unsupported = fields
        .where((field) => !allowedFields.contains(field))
        .toList();
    if (unsupported.isEmpty) {
      appLogger.d(
        'Local firestore.rules field check passed: $documentPath '
        'fields=${fields.toList()}',
      );
      return;
    }

    appLogger.e(
      'Local firestore.rules field mismatch: $documentPath '
      'unsupportedFields=$unsupported allowedFields=$allowedFields',
    );
  }

  static Map<String, dynamic> _publicProfileData(
    String uid,
    Map<String, dynamic> source,
  ) {
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
    return publicData;
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
