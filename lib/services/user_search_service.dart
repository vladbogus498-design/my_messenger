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
    
    final byName = await _fs
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: sanitizedQuery)
        .where('username', isLessThan: sanitizedQuery + '\uf8ff')
        .limit(20)
        .get();
    final byEmail = await _fs
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: sanitizedQuery)
        .where('email', isLessThan: sanitizedQuery + '\uf8ff')
        .limit(20)
        .get();
    final byPhone = await _fs
        .collection('users')
        .where('phone', isGreaterThanOrEqualTo: sanitizedQuery)
        .where('phone', isLessThan: sanitizedQuery + '\uf8ff')
        .limit(20)
        .get();

    final all = <UserModel>[];
    for (final d in byName.docs) {
      all.add(UserModel.fromMap({...d.data(), 'uid': d.id}));
    }
    for (final d in byEmail.docs) {
      all.add(UserModel.fromMap({...d.data(), 'uid': d.id}));
    }
    for (final d in byPhone.docs) {
      all.add(UserModel.fromMap({...d.data(), 'uid': d.id}));
    }
    // de-dup by uid
    final seen = <String>{};
    return all.where((u) => seen.add(u.uid)).toList();
  }
}
