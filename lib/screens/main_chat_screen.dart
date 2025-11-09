import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';
import 'profile_screen.dart';

class MainChatScreen extends StatefulWidget {
  @override
  _MainChatScreenState createState() => _MainChatScreenState();
}

class _MainChatScreenState extends State<MainChatScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    ChatScreen(),
    ContactsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedIndex();
  }

  void _loadSavedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIndex = prefs.getInt('currentIndex') ?? 0;
    });
  }

  void _onItemTapped(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentIndex', index);

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).bottomAppBarTheme.color ??
        (isDark ? colorScheme.surfaceVariant : colorScheme.surface);
    final selected = Theme.of(context).bottomNavigationBarTheme.selectedItemColor ??
        colorScheme.primary;
    final unselected =
        Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ??
            colorScheme.onSurfaceVariant;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        backgroundColor: background,
        selectedItemColor: selected,
        unselectedItemColor: unselected,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
