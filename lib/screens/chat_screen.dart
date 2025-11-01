import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart' as service;
import '../models/chat.dart' as model;
import 'single_chat_screen.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<model.Chat> _chats = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // DEMO CHATS
  final List<model.Chat> _demoChats = [
    model.Chat(
      id: '1',
      name: 'DarkKick Team',
      participants: ['you', 'dev'],
      lastMessage: 'Welcome to DarkKick! Messages self-destruct 🔥',
      lastMessageStatus: 'read',
      lastMessageTime: DateTime.now().subtract(Duration(minutes: 2)),
    ),
    model.Chat(
      id: '2',
      name: 'Flutter Developers',
      participants: ['you', 'flutter', 'firebase'],
      lastMessage: 'This chat disappears in 5 seconds...',
      lastMessageStatus: 'read',
      lastMessageTime: DateTime.now().subtract(Duration(minutes: 5)),
    ),
    model.Chat(
      id: '3',
      name: 'Secret Group',
      participants: ['you', 'friend1', 'friend2'],
      lastMessage: 'Mission: Create the best messenger!',
      lastMessageStatus: 'read',
      lastMessageTime: DateTime.now().subtract(Duration(minutes: 10)),
    ),
    model.Chat(
      id: '4',
      name: 'Ephemeral Chat',
      participants: ['you', 'anonymous'],
      lastMessage: 'Try the self-destruct feature! 💣',
      lastMessageStatus: 'read',
      lastMessageTime: DateTime.now().subtract(Duration(minutes: 1)),
    ),
  ];

  List<model.Chat> get _filteredChats {
    if (_searchController.text.isEmpty) return _chats;
    return _chats
        .where((chat) => chat.name
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      final firebaseChats = await service.ChatService.getUserChats();
      setState(() {
        _chats = [..._demoChats, ...firebaseChats];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _chats = _demoChats;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadChats();
  }

  void _createTestChat() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Creating test chat...')),
      );
      service.ChatService.createTestChat();
      await Future.delayed(Duration(seconds: 2));
      _loadChats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showSelfDestructDemo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Self-Destruct Feature'),
        content: Text('🔥 Messages disappear automatically!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('COOL!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DarkKick Chats'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: _createTestChat),
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadChats),
        ],
      ),
      body: Container(
        color: Colors.grey[900],
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredChats.isEmpty
                      ? Center(child: Text('No chats yet'))
                      : ListView.builder(
                          itemCount: _filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = _filteredChats[index];
                            final isDemoChat =
                                _demoChats.any((c) => c.id == chat.id);

                            return Card(
                              color: Colors.grey[800],
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDemoChat
                                      ? Colors.green
                                      : Colors.deepPurple,
                                  child: Text(chat.name[0]),
                                ),
                                title: Text(chat.name,
                                    style: TextStyle(color: Colors.white)),
                                subtitle: Text(chat.lastMessage,
                                    style: TextStyle(color: Colors.grey)),
                                trailing: Text(
                                  '${chat.lastMessageTime.hour}:${chat.lastMessageTime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SingleChatScreen(
                                        chatId: chat.id,
                                        chatName: chat.name,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
