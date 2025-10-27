import 'package:flutter/material.dart';
import 'profile_screen.dart'; // ДОБАВИМ ИМПОРТ ПРОФИЛЯ

class SingleChatScreen extends StatelessWidget {
  final String chatId;

  SingleChatScreen({required this.chatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          // ДЕЛАЕМ ТАПАБЕЛЬНЫМ
          onTap: () {
            // ПЕРЕХОД НА ПРОФИЛЬ
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                child: Text('U'),
              ),
              SizedBox(width: 10),
              Text('Имя пользователя'),
            ],
          ),
        ),
      ),
      body: Container(),
    );
  }
}
