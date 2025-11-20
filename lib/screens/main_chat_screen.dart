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
  bool _isLoadingIndex = true;

  // Используем IndexedStack для сохранения состояния экранов
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt('currentIndex') ?? 0;
      if (mounted) {
        setState(() {
          _currentIndex = savedIndex;
          _isLoadingIndex = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentIndex = 0;
          _isLoadingIndex = false;
        });
      }
    }
  }

  void _onItemTapped(int index) async {
    // Предотвращаем повторное нажатие на ту же вкладку
    if (index == _currentIndex) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('currentIndex', index);

      if (mounted) {
        setState(() {
          _currentIndex = index;
        });
      }
    } catch (e) {
      // Ошибка сохранения индекса не критична, можно игнорировать
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingIndex) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
      // IndexedStack сохраняет состояние экранов при переключении
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
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
