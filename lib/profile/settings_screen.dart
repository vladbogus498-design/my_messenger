import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../../models/user_model.dart';
import '../search/user_search_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        setState(() {
          _userProfile = UserProfile.fromMap(doc.data()!);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки профиля: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final usernameController =
        TextEditingController(text: _userProfile?.username ?? '');
    final bioController = TextEditingController(text: _userProfile?.bio ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.currentLanguage == 'ru'
            ? 'Редактировать профиль'
            : 'Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFDC143C),
              child: _userProfile?.avatarUrl.isNotEmpty == true
                  ? ClipOval(child: Image.network(_userProfile!.avatarUrl))
                  : Text(_userProfile?.username[0].toUpperCase() ?? 'U',
                      style: TextStyle(fontSize: 24, color: Colors.white)),
            ),
            SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                  labelText: languageProvider.currentLanguage == 'ru'
                      ? 'Имя пользователя'
                      : 'Username'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: InputDecoration(
                  labelText: languageProvider.currentLanguage == 'ru'
                      ? 'Описание профиля'
                      : 'Bio',
                  hintText: languageProvider.currentLanguage == 'ru'
                      ? 'Расскажите о себе...'
                      : 'Tell about yourself...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
                languageProvider.currentLanguage == 'ru' ? 'Отмена' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (usernameController.text.isNotEmpty) {
                try {
                  final userId = FirebaseAuth.instance.currentUser!.uid;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({
                    'username': usernameController.text,
                    'bio': bioController.text,
                  });
                  Navigator.pop(context);
                  _loadUserProfile();
                } catch (e) {
                  print('Ошибка обновления профиля: $e');
                }
              }
            },
            child: Text(languageProvider.currentLanguage == 'ru'
                ? 'Сохранить'
                : 'Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFDC143C),
            child: _userProfile?.avatarUrl.isNotEmpty == true
                ? ClipOval(child: Image.network(_userProfile!.avatarUrl))
                : Text(_userProfile?.username[0].toUpperCase() ?? 'U',
                    style: TextStyle(fontSize: 20, color: Colors.white)),
          ),
          title: Text(_userProfile?.username ?? user?.email ?? 'Пользователь'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.email ?? ''),
              if (_userProfile?.bio?.isNotEmpty == true)
                Text(_userProfile!.bio,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              if (_userProfile?.createdAt != null)
                Text(
                    '${languageProvider.currentLanguage == 'ru' ? 'Зарегистрирован' : 'Registered'}: ${_formatDate(_userProfile!.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editProfile,
          ),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.people, color: Color(0xFFDC143C)),
          title: Text(languageProvider.currentLanguage == 'ru'
              ? 'Поиск пользователей'
              : 'User search'),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        UserSearchScreen()) // ← ДОЛЖНО БЫТЬ ТАК
                );
          },
        ),
        ListTile(
          leading: Icon(Icons.logout, color: Color(0xFFDC143C)),
          title: Text(
              languageProvider.currentLanguage == 'ru' ? 'Выйти' : 'Logout'),
          onTap: () => FirebaseAuth.instance.signOut(),
        ),
      ],
    );
  }
}

class UserSearchScreen {}
