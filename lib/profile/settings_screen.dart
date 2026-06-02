import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final String language;

  const SettingsScreen({required this.language});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language == 'ru' ? 'Настройки' : 'Settings'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text(language == 'ru' ? 'Профиль' : 'Profile'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text(language == 'ru' ? 'Уведомления' : 'Notifications'),
            trailing: Switch(value: true, onChanged: (value) {}),
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text(language == 'ru' ? 'Язык' : 'Language'),
            subtitle: Text(language == 'ru' ? 'Русский' : 'English'),
          ),
          ListTile(
            leading: Icon(Icons.security),
            title: Text(language == 'ru' ? 'Безопасность' : 'Security'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text(language == 'ru' ? 'Помощь' : 'Help'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
