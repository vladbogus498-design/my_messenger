import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import '../search/user_search_screen.dart';

class MainChatScreen extends StatefulWidget {
  const MainChatScreen({super.key});

  @override
  _MainChatScreenState createState() => _MainChatScreenState();
}

class _MainChatScreenState extends State<MainChatScreen> {
  int _currentIndex = 0;
  List<Chat> _chats = [];
  List<Chat> _filteredChats = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChats();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredChats = _chats;
      });
    } else {
      setState(() {
        _filteredChats = _chats
            .where((chat) => chat.name.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  Future<void> _loadChats() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      final snapshot =
          await FirebaseFirestore.instance.collection('chats').get();

      final chats = <Chat>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);

        if (participants.contains(userId)) {
          chats.add(Chat(
            id: doc.id,
            name: data['name'] ?? 'Чат',
            lastMessage: data['lastMessage'] ?? 'Нет сообщений',
            time: _formatTime(data['lastMessageTime']),
            unread: data['unreadCount']?[userId] ?? 0,
            participants: participants,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _chats = chats;
          _filteredChats = chats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Ошибка загрузки чатов: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}.${date.month}';
    }
  }

  Future<void> _createNewChat() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.currentLanguage == 'ru'
            ? 'Создать новый чат'
            : 'Create new chat'),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
              hintText: languageProvider.currentLanguage == 'ru'
                  ? 'Название чата'
                  : 'Chat name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
                languageProvider.currentLanguage == 'ru' ? 'Отмена' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                try {
                  final chatDoc =
                      FirebaseFirestore.instance.collection('chats').doc();
                  await chatDoc.set({
                    'id': chatDoc.id,
                    'name': textController.text,
                    'participants': [userId],
                    'createdAt': FieldValue.serverTimestamp(),
                    'lastMessage': languageProvider.currentLanguage == 'ru'
                        ? 'Чат создан'
                        : 'Chat created',
                    'lastMessageTime': FieldValue.serverTimestamp(),
                    'unreadCount': {userId: 0},
                  });

                  await chatDoc.collection('messages').add({
                    'text': languageProvider.currentLanguage == 'ru'
                        ? 'Чат создан'
                        : 'Chat created',
                    'senderId': 'system',
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': 'text',
                    'isRead': false,
                  });

                  Navigator.pop(context);
                  _loadChats();
                } catch (e) {
                  print('Ошибка создания чата: $e');
                }
              }
            },
            child: Text(languageProvider.currentLanguage == 'ru'
                ? 'Создать'
                : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(String chatId) async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.currentLanguage == 'ru'
            ? 'Удалить чат?'
            : 'Delete chat?'),
        content: Text(languageProvider.currentLanguage == 'ru'
            ? 'Вы уверены что хотите удалить этот чат?'
            : 'Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
                languageProvider.currentLanguage == 'ru' ? 'Отмена' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(languageProvider.currentLanguage == 'ru'
                ? 'Удалить'
                : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .delete();
        _loadChats();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(languageProvider.currentLanguage == 'ru'
                  ? 'Чат удален'
                  : 'Chat deleted')),
        );
      } catch (e) {
        print('Ошибка удаления чата: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(languageProvider.currentLanguage == 'ru'
                  ? 'Ошибка удаления чата'
                  : 'Error deleting chat')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: _currentIndex == 0
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: languageProvider.currentLanguage == 'ru'
                      ? 'Поиск чатов...'
                      : 'Search chats...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: TextStyle(color: Colors.white),
              )
            : Text(languageProvider.currentLanguage == 'ru'
                ? 'Настройки'
                : 'Settings'),
        backgroundColor: Color(0xFF8B0000),
        actions: [
          if (_currentIndex == 0) ...[
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadChats,
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _createNewChat,
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (language) => languageProvider.setLanguage(language),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'ru', child: Text('🇷🇺 Русский')),
              PopupMenuItem(value: 'en', child: Text('🇺🇸 English')),
            ],
            icon: Icon(Icons.language, color: Colors.white),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildChatsScreen() : SettingsScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label:
                  languageProvider.currentLanguage == 'ru' ? 'Чаты' : 'Chats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: languageProvider.currentLanguage == 'ru'
                  ? 'Настройки'
                  : 'Settings'),
        ],
      ),
    );
  }

  Widget _buildChatsScreen() {
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_filteredChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
                languageProvider.currentLanguage == 'ru'
                    ? 'Нет чатов'
                    : 'No chats',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text(
                languageProvider.currentLanguage == 'ru'
                    ? 'Создайте новый чат или обновите список'
                    : 'Create a new chat or refresh the list',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadChats,
              child: Text(languageProvider.currentLanguage == 'ru'
                  ? 'Обновить'
                  : 'Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredChats.length,
      itemBuilder: (context, index) {
        final chat = _filteredChats[index];
        return Dismissible(
          key: Key(chat.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) => _deleteChat(chat.id),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFFDC143C),
              child: Text(chat.name[0], style: TextStyle(color: Colors.white)),
            ),
            title: Text(chat.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            subtitle: Text(chat.lastMessage,
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(chat.time,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                if (chat.unread > 0)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color(0xFFDC143C),
                      shape: BoxShape.circle,
                    ),
                    child: Text(chat.unread.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChatScreen(chat: chat)));
            },
          ),
        );
      },
    );
  }
}
