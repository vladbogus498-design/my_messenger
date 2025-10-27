import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:darkkick_messenger/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'DARKKICK',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Версия 1.0',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 30),
                Card(
                  color: Colors.grey[800],
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.red,
                          child:
                              Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        SizedBox(height: 15),
                        Text('+48 XXX XXX XXX',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                        SizedBox(height: 8),
                        Text('Имя Пользователя',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        SizedBox(height: 8),
                        Text('О себе: Тут будет описание',
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 25),
                Card(
                  color: Colors.grey[800],
                  child: ListTile(
                    leading: Icon(Icons.light_mode, color: Colors.white),
                    title: Text('Тёмная тема',
                        style: TextStyle(color: Colors.white)),
                    trailing: Switch(value: true, onChanged: (value) {}),
                  ),
                ),
                SizedBox(height: 10),
                Card(
                  color: Colors.grey[800],
                  child: Column(
                    children: [
                      ListTile(
                          leading: Icon(Icons.chat, color: Colors.white),
                          title: Text("Настройки чатов",
                              style: TextStyle(color: Colors.white))),
                      ListTile(
                          leading: Icon(Icons.security, color: Colors.white),
                          title: Text("Конфиденциальность",
                              style: TextStyle(color: Colors.white))),
                      ListTile(
                          leading:
                              Icon(Icons.notifications, color: Colors.white),
                          title: Text("Уведомления и звук",
                              style: TextStyle(color: Colors.white))),
                      ListTile(
                          leading: Icon(Icons.storage, color: Colors.white),
                          title: Text("Память устройства",
                              style: TextStyle(color: Colors.white))),
                      ListTile(
                          leading: Icon(Icons.help, color: Colors.white),
                          title: Text("Помощь",
                              style: TextStyle(color: Colors.white))),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LoginScreen(
                                language: 'ru',
                              )),
                      (route) => false,
                    );
                  },
                  child: Text('Выйти', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[800]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
