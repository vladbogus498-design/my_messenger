import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'chat_screen.dart';
import 'user_search_screen.dart';
import 'profile_screen.dart';

class MainChatScreen extends StatefulWidget {
  @override
  _MainChatScreenState createState() => _MainChatScreenState();
}

class _MainChatScreenState extends State<MainChatScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    UserSearchScreen(),
    ChatScreen(),
    ProfileScreen(), // Теперь без параметров
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Контакты'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Чаты'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}
