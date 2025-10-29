import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../models/chat.dart';
import 'single_chat_screen.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Chat> _chats = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // DEMO CHATS - IMMEDIATELY VISIBLE
  final List<Chat> _demoChats = [
    Chat(
      id: '1',
      name: 'DarkKick Team',
      participants: ['you', 'dev'],
      lastMessage: 'Welcome to DarkKick! Messages self-destruct 🔥',
      lastMessageStatus: 'read',
      lastMessageTime: DateTime.now().subtract(Duration(minutes: 2)),
    ),
    Chat(
      id: '2',
      name: 'Flutter Developers',
      participants: ['you', 'flutter', 'firebase'],
      lastMessage: 'This chat disappears in 5 seconds...',
      lastMessageStatus: 'read',
      lastMessageTime: DateTime.now().subtract(Duration(minutes: 5)),
    ),
    Chat(
      id: '3',
      name: 'Secret Group',
      participants: ['you', 'friend1', 'friend2'],
      lastMessage: 'Mission: Create the best messenger!',
      lastMessageStatus: 'read',
      lastMessageTime: DateTime.now().subtract(Duration(minutes: 10)),
    ),
    Chat(
      id: '4',
      name: 'Ephemeral Chat',
      participants: ['you', 'anonymous'],
      lastMessage: 'Try the self-destruct feature! 💣',
      lastMessageStatus: 'read',
      lastMessageTime: DateTime.now().subtract(Duration(minutes: 1)),
    ),
  ];

  List<Chat> get _filteredChats {
    if (_searchController.text.isEmpty) {
      return _chats;
    }
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

  // Load chats - mix of demo and Firebase chats
  Future<void> _loadChats() async {
    print('🔄 Loading chats...');
    setState(() => _isLoading = true);

    try {
      final firebaseChats = await ChatService.getUserChats();

      // Combine demo chats with Firebase chats
      setState(() {
        _chats = [..._demoChats, ...firebaseChats];
        _isLoading = false;
      });

      print('✅ Loaded ${_chats.length} chats total');
    } catch (e) {
      // If Firebase fails, use only demo chats
      setState(() {
        _chats = _demoChats;
        _isLoading = false;
      });
      print('⚠️ Using demo chats: $e');
    }
  }

  Future<void> _handleRefresh() async {
    await _loadChats();
  }

  void _createTestChat() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.schedule, color: Colors.white),
              SizedBox(width: 8),
              Text('Creating test chat...'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );

      ChatService.createTestChat();

      await Future.delayed(Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text('Test chat created! Refreshing...'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      _loadChats();
    } catch (e) {
      print('❌ Error creating chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Error: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSelfDestructDemo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Self-Destruct Feature',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '🔥 Messages disappear automatically!\n\n'
          '• Set timer: 5sec to 1 week\n'
          '• Whole chats can self-destruct\n'
          '• Complete privacy control',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('COOL!', style: TextStyle(color: Colors.deepPurple)),
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
          IconButton(
            icon: Icon(Icons.autorenew, color: Colors.white),
            onPressed: _showSelfDestructDemo,
            tooltip: 'Self-Destruct Demo',
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _createTestChat,
            tooltip: 'Create Test Chat',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadChats,
            tooltip: 'Refresh Chats',
          ),
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
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
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
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: _isLoading
                    ? Center(
                        child:
                            CircularProgressIndicator(color: Colors.deepPurple))
                    : _filteredChats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No chats yet',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Press + to create a test chat',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _createTestChat,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                  ),
                                  child: Text('Create Test Chat'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredChats.length,
                            itemBuilder: (context, index) {
                              final chat = _filteredChats[index];
                              final isDemoChat =
                                  _demoChats.any((c) => c.id == chat.id);

                              return Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                color: Colors.grey[800],
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isDemoChat
                                        ? Colors.green
                                        : Colors.deepPurple,
                                    child: Text(
                                      chat.name.isNotEmpty
                                          ? chat.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        chat.name,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      if (isDemoChat) ...[
                                        SizedBox(width: 6),
                                        Icon(Icons.star,
                                            color: Colors.yellow, size: 16),
                                      ]
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        chat.lastMessage,
                                        style: TextStyle(color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Participants: ${chat.participants.length}',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${chat.lastMessageTime.hour}:${chat.lastMessageTime.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                      if (isDemoChat)
                                        Text(
                                          'DEMO',
                                          style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        ),
                                    ],
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSelfDestructDemo,
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.auto_delete, color: Colors.white),
        tooltip: 'Self-Destruct Feature',
      ),
    );
  }
}
