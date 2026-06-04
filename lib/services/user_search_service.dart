import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/input_validator.dart';

class UserSearchService {
  static final FirebaseFirestore _fs = FirebaseFirestore.instance;

  static Future<List<UserModel>> searchUnified(String query) async {
    if (query.isEmpty) return [];

    // Санитизация поискового запроса (защита от NoSQL injection)
    final sanitizedQuery = InputValidator.sanitizeSearchQuery(query);
    if (sanitizedQuery.isEmpty) return [];

    final normalizedQuery = sanitizedQuery.toLowerCase();
    final byName = await _fs
        .collection('publicProfiles')
        .where('nameLower', isGreaterThanOrEqualTo: normalizedQuery)
        .where('nameLower', isLessThan: '$normalizedQuery\uf8ff')
        .limit(20)
        .get();
    final byUsername = await _fs
        .collection('publicProfiles')
        .where('usernameLower', isGreaterThanOrEqualTo: normalizedQuery)
        .where('usernameLower', isLessThan: '$normalizedQuery\uf8ff')
        .limit(20)
        .get();
    final byTag = await _fs
        .collection('publicProfiles')
        .where('tagLower', isGreaterThanOrEqualTo: normalizedQuery)
        .where('tagLower', isLessThan: '$normalizedQuery\uf8ff')
        .limit(20)
        .get();

    final all = <UserModel>[];
    for (final d in byName.docs) {
      all.add(UserModel.fromMap({...d.data(), 'uid': d.id}));
    }
    for (final d in byUsername.docs) {
      all.add(UserModel.fromMap({...d.data(), 'uid': d.id}));
    }
    for (final d in byTag.docs) {
      all.add(UserModel.fromMap({...d.data(), 'uid': d.id}));
    }
    // de-dup by uid
    final seen = <String>{};
    return all.where((u) => seen.add(u.uid)).toList();
  }
}
