import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/group_chat_service.dart';

class GroupCreateScreen extends StatefulWidget {
  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final TextEditingController _name = TextEditingController();
  final Set<String> _selected = {};
  bool _isCreating = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Создать группу')),
        body: Center(child: Text('Необходима авторизация')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Создать группу', style: GoogleFonts.montserrat()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Название группы',
                hintText: 'Например, "Команда 🔥"',
                prefixIcon: Icon(Icons.group),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.people, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Выберите участников (${_selected.length})',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, isNotEqualTo: uid)
                  .snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Нет доступных пользователей',
                      style: GoogleFonts.montserrat(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                final docs = snap.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final id = d.id;
                    final data = d.data();
                    final selected = _selected.contains(id);
                    final name = data['name'] ?? id;
                    final email = data['email'] ?? '';
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (v) {
                        setState(() {
                          if (selected) {
                            _selected.remove(id);
                          } else {
                            _selected.add(id);
                          }
                        });
                      },
                      title: Text(name, style: GoogleFonts.montserrat()),
                      subtitle: email.isNotEmpty
                          ? Text(email, style: GoogleFonts.montserrat(fontSize: 12))
                          : null,
                      secondary: CircleAvatar(
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreating
                      ? null
                      : () async {
                          final creator = uid;
                          final name = _name.text.trim();
                          if (creator == null || name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Введите название группы'),
                              ),
                            );
                            return;
                          }
                          setState(() => _isCreating = true);
                          try {
                            final chatId = await GroupChatService.createGroup(
                              name: name,
                              participantIds: [creator, ..._selected],
                              creatorId: creator,
                            );
                            if (!mounted) return;
                            Navigator.pop(context, chatId);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ошибка создания группы: $e'),
                              ),
                            );
                            setState(() => _isCreating = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isCreating
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'СОЗДАТЬ ГРУППУ',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
