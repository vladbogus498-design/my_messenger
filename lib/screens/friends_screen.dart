import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/friend_service.dart';

class FriendsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(body: Center(child: Text('Not signed in')));
    }
    final users = FirebaseFirestore.instance.collection('users');
    return Scaffold(
      appBar: AppBar(title: Text('Друзья')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: users.doc(uid).snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());
          final data = snap.data!.data() ?? {};
          final friends = List<String>.from(data['friendsList'] ?? const []);
          final requests =
              List<String>.from(data['friendRequests'] ?? const []);
          return ListView(
            children: [
              ListTile(
                  title: Text('Запросы в друзья',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              ...requests.map((id) => ListTile(
                    title: Text(id),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                          icon: Icon(Icons.check),
                          onPressed: () =>
                              FriendService.acceptFriendRequest(id)),
                      IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () =>
                              FriendService.declineFriendRequest(id)),
                    ]),
                  )),
              Divider(),
              ListTile(
                  title: Text('Друзья',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              ...friends.map((id) => ListTile(title: Text(id))),
            ],
          );
        },
      ),
    );
  }
}
