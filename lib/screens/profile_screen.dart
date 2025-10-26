import 'package:flutter/material.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;
  final String language;

  const ProfileScreen({required this.user, required this.language});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(language == 'ru' ? 'Профиль' : 'Profile'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Аватар
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.red,
              child: user.photoURL != null
                  ? CircleAvatar(
                      radius: 48, backgroundImage: NetworkImage(user.photoURL!))
                  : Text(user.name[0],
                      style: TextStyle(fontSize: 30, color: Colors.white)),
            ),
            SizedBox(height: 20),

            // Имя
            Text(
              user.name,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 10),

            // Email
            Text(
              user.email,
              style: TextStyle(fontSize: 16, color: Colors.red[300]),
            ),
            SizedBox(height: 20),

            // Описание профиля
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language == 'ru' ? 'О себе' : 'About me',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                    SizedBox(height: 8),
                    Text(
                      user.bio!,
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],

            // Статистика
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    language == 'ru' ? 'Статистика' : 'Statistics',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(language == 'ru' ? 'Чаты' : 'Chats', '5'),
                      _buildStatItem(
                          language == 'ru' ? 'Друзья' : 'Friends', '12'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.red[300])),
      ],
    );
  }
}
