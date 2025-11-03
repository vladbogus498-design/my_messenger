import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/group_chat_service.dart';

class GroupCreateScreen extends StatefulWidget {
  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final TextEditingController _name = TextEditingController();
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: Text('Создать группу')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              controller: _name,
              decoration: InputDecoration(labelText: 'Название группы'),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (_, snap) {
                if (!snap.hasData)
                  return Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs.where((d) => d.id != uid).toList();
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final id = d.id;
                    final selected = _selected.contains(id);
                    return ListTile(
                      title: Text(d.data()['name'] ?? id),
                      subtitle: Text(d.data()['email'] ?? ''),
                      trailing: Checkbox(
                          value: selected,
                          onChanged: (v) {
                            setState(() {
                              if (selected)
                                _selected.remove(id);
                              else
                                _selected.add(id);
                            });
                          }),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final creator = uid;
                    if (creator == null ||
                        _name.text.trim().isEmpty ||
                        _selected.isEmpty) return;
                    final chatId = await GroupChatService.createGroup(
                      name: _name.text.trim(),
                      participantIds: [creator, ..._selected],
                      creatorId: creator,
                    );
                    if (!mounted) return;
                    Navigator.pop(context, chatId);
                  },
                  child: Text('СОЗДАТЬ'),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
