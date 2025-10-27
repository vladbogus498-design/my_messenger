import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'DarkKick',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Версия 1.0',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 30),

            // Инфа о пользователе
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.person, size: 40),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'User_${DateTime.now().millisecondsSinceEpoch % 1000}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text('Статус: онлайн'),
                    SizedBox(height: 5),
                    Text('ID: ${DateTime.now().millisecondsSinceEpoch}'),
                  ],
                ),
              ),
            ),

            // Кнопка выхода
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Твой код выхода
                print('Выход из аккаунта');
              },
              child: Text('Выйти'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
