import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  static final _fs = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> sendFriendRequest(String toUserId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _fs.collection('users').doc(toUserId).update({
      'friendRequests': FieldValue.arrayUnion([uid])
    });
  }

  static Future<void> acceptFriendRequest(String fromUserId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final batch = _fs.batch();
    final me = _fs.collection('users').doc(uid);
    final other = _fs.collection('users').doc(fromUserId);
    batch.update(me, {
      'friendsList': FieldValue.arrayUnion([fromUserId]),
      'friendRequests': FieldValue.arrayRemove([fromUserId]),
    });
    batch.update(other, {
      'friendsList': FieldValue.arrayUnion([uid]),
    });
    await batch.commit();
  }

  static Future<void> declineFriendRequest(String fromUserId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _fs.collection('users').doc(uid).update({
      'friendRequests': FieldValue.arrayRemove([fromUserId])
    });
  }
}
