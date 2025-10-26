import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';

// КОНФИГУРАЦИЯ FIREBASE
const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyC_wZVPV1csibeOs7isMdZeAJjpZ9XO0BQ",
  authDomain: "darkkickchat-765e0.firebaseapp.com",
  projectId: "darkkickchat-765e0",
  storageBucket: "darkkickchat-765e0.firebasestorage.app",
  messagingSenderId: "366138349689",
  appId: "1:366138349689:web:58d15e2f8ad82415961ca8",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseConfig);

  runApp(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: const Color(0xFFDC143C),
        scaffoldBackgroundColor: Colors.black,
      ),
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    ),
  );
}

// ПРОВАЙДЕР ЯЗЫКА
class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'ru';

  String get currentLanguage => _currentLanguage;

  void setLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }

  String get loginButtonText => _currentLanguage == 'ru' ? 'ВОЙТИ' : 'LOGIN';
  String get registerButtonText =>
      _currentLanguage == 'ru' ? 'СОЗДАТЬ АККАУНТ' : 'CREATE ACCOUNT';
  String get loginTabText => _currentLanguage == 'ru' ? 'Вход' : 'Login';
  String get registerTabText =>
      _currentLanguage == 'ru' ? 'Регистрация' : 'Register';
  String get emailLabel => 'Email';
  String get passwordLabel => _currentLanguage == 'ru' ? 'Пароль' : 'Password';
  String get appTitle => 'DARKKICK';
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LanguageProvider(),
      child: MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          _setUserOnline(snapshot.data!.uid);
          return MainChatScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }

  Future<void> _setUserOnline(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

// ЭКРАН ЛОГИНА
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  bool _validateInputs() {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    if (_emailController.text.isEmpty) {
      _showError(languageProvider.currentLanguage == 'ru'
          ? 'Введите email'
          : 'Enter email');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      _showError(languageProvider.currentLanguage == 'ru'
          ? 'Введите корректный email'
          : 'Enter valid email');
      return false;
    }
    if (_passwordController.text.isEmpty) {
      _showError(languageProvider.currentLanguage == 'ru'
          ? 'Введите пароль'
          : 'Enter password');
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showError(languageProvider.currentLanguage == 'ru'
          ? 'Пароль должен содержать минимум 6 символов'
          : 'Password must be at least 6 characters');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _createUserProfile(String userId, String email) async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'userId': userId,
      'email': email,
      'username': email.split('@')[0],
      'avatarUrl': '',
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'language': languageProvider.currentLanguage,
      'typingStatus': null,
      'bio': '',
    }, SetOptions(merge: true));
  }

  Future<void> _createDemoChats(String userId) async {
    try {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      final demoChats = languageProvider.currentLanguage == 'ru'
          ? [
              {'name': 'Андрей', 'lastMessage': 'Привет! Как дела?'},
              {'name': 'Мама', 'lastMessage': 'Не забудь купить хлеб'},
              {'name': 'Работа', 'lastMessage': 'Совещание в 15:00'},
            ]
          : [
              {'name': 'Andrew', 'lastMessage': 'Hi! How are you?'},
              {'name': 'Mom', 'lastMessage': 'Don\'t forget to buy bread'},
              {'name': 'Work', 'lastMessage': 'Meeting at 3:00 PM'},
            ];

      for (final chat in demoChats) {
        final chatDoc = FirebaseFirestore.instance.collection('chats').doc();
        await chatDoc.set({
          'id': chatDoc.id,
          'name': chat['name'],
          'participants': [userId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': chat['lastMessage'],
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {userId: 0},
        });

        await chatDoc.collection('messages').add({
          'text': chat['lastMessage']!,
          'senderId': 'system',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'text',
          'isRead': false,
        });
      }
    } catch (e) {
      print("❌ ОШИБКА СОЗДАНИЯ ДЕМО-ЧАТОВ: $e");
    }
  }

  Future<void> _auth() async {
    if (!_validateInputs()) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        await _createUserProfile(
            userCredential.user!.uid, _emailController.text);
        await _createDemoChats(userCredential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      String errorMessage = 'Ошибка: ${e.code}';
      if (languageProvider.currentLanguage == 'en') {
        if (e.code == 'user-not-found')
          errorMessage = 'User not found';
        else if (e.code == 'wrong-password')
          errorMessage = 'Wrong password';
        else if (e.code == 'email-already-in-use')
          errorMessage = 'Email already in use';
        else if (e.code == 'weak-password')
          errorMessage = 'Weak password';
        else
          errorMessage = 'Error: ${e.code}';
      } else {
        if (e.code == 'user-not-found')
          errorMessage = 'Пользователь не найден';
        else if (e.code == 'wrong-password')
          errorMessage = 'Неверный пароль';
        else if (e.code == 'email-already-in-use')
          errorMessage = 'Email уже используется';
        else if (e.code == 'weak-password') errorMessage = 'Слабый пароль';
      }
      _showError(errorMessage);
    } catch (e) {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      _showError(languageProvider.currentLanguage == 'ru'
          ? 'Произошла ошибка: $e'
          : 'An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (language) => languageProvider.setLanguage(language),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'ru', child: Text('🇷🇺 Русский')),
              PopupMenuItem(value: 'en', child: Text('🇺🇸 English')),
            ],
            icon: Icon(Icons.language, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Color(0xFFDC143C),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology, size: 60, color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(languageProvider.appTitle,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                  color: Color(0xFF1a0000),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isLogin = true),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          _isLogin ? Color(0xFFDC143C) : Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(languageProvider.loginTabText,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isLogin = false),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          !_isLogin ? Color(0xFFDC143C) : Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(languageProvider.registerTabText,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              enabled: !_isLoading,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: languageProvider.emailLabel,
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'test@gmail.com',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFDC143C))),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              enabled: !_isLoading,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: languageProvider.passwordLabel,
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFDC143C))),
              ),
              obscureText: true,
            ),
            SizedBox(height: 25),
            if (_isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _auth,
                child: Text(
                    _isLogin
                        ? languageProvider.loginButtonText
                        : languageProvider.registerButtonText,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Color(0xFFDC143C),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// МОДЕЛИ ДАННЫХ
class Chat {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final List<String> participants;

  Chat(
      {required this.id,
      required this.name,
      required this.lastMessage,
      required this.time,
      required this.unread,
      required this.participants});
}

class Message {
  final String id;
  final String text;
  final bool isMe;
  final String time;
  final String senderId;
  final String type;
  final bool isRead;

  Message(
      {required this.id,
      required this.text,
      required this.isMe,
      required this.time,
      required this.senderId,
      this.type = 'text',
      this.isRead = false});
}

class UserProfile {
  final String userId;
  final String email;
  final String username;
  final String avatarUrl;
  final Timestamp createdAt;
  final bool isOnline;
  final Timestamp lastSeen;
  final String? typingStatus;
  final String bio;

  UserProfile({
    required this.userId,
    required this.email,
    required this.username,
    required this.avatarUrl,
    required this.createdAt,
    required this.isOnline,
    required this.lastSeen,
    this.typingStatus,
    this.bio = '',
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      userId: data['userId'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'] ?? Timestamp.now(),
      typingStatus: data['typingStatus'],
      bio: data['bio'] ?? '',
    );
  }
}

// ГЛАВНЫЙ ЭКРАН ЧАТОВ
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
      body: _currentIndex == 0 ? _buildChatsScreen() : _buildSettingsScreen(),
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

  Widget _buildSettingsScreen() {
    return SettingsScreen();
  }
}

// ЭКРАН НАСТРОЕК
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        setState(() {
          _userProfile = UserProfile.fromMap(doc.data()!);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки профиля: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final usernameController =
        TextEditingController(text: _userProfile?.username ?? '');
    final bioController = TextEditingController(text: _userProfile?.bio ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.currentLanguage == 'ru'
            ? 'Редактировать профиль'
            : 'Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFDC143C),
              child: _userProfile?.avatarUrl.isNotEmpty == true
                  ? ClipOval(child: Image.network(_userProfile!.avatarUrl))
                  : Text(_userProfile?.username[0].toUpperCase() ?? 'U',
                      style: TextStyle(fontSize: 24, color: Colors.white)),
            ),
            SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                  labelText: languageProvider.currentLanguage == 'ru'
                      ? 'Имя пользователя'
                      : 'Username'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: InputDecoration(
                  labelText: languageProvider.currentLanguage == 'ru'
                      ? 'Описание профиля'
                      : 'Bio',
                  hintText: languageProvider.currentLanguage == 'ru'
                      ? 'Расскажите о себе...'
                      : 'Tell about yourself...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
                languageProvider.currentLanguage == 'ru' ? 'Отмена' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (usernameController.text.isNotEmpty) {
                try {
                  final userId = FirebaseAuth.instance.currentUser!.uid;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({
                    'username': usernameController.text,
                    'bio': bioController.text,
                  });
                  Navigator.pop(context);
                  _loadUserProfile();
                } catch (e) {
                  print('Ошибка обновления профиля: $e');
                }
              }
            },
            child: Text(languageProvider.currentLanguage == 'ru'
                ? 'Сохранить'
                : 'Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFDC143C),
            child: _userProfile?.avatarUrl.isNotEmpty == true
                ? ClipOval(child: Image.network(_userProfile!.avatarUrl))
                : Text(_userProfile?.username[0].toUpperCase() ?? 'U',
                    style: TextStyle(fontSize: 20, color: Colors.white)),
          ),
          title: Text(_userProfile?.username ?? user?.email ?? 'Пользователь'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.email ?? ''),
              if (_userProfile?.bio?.isNotEmpty == true)
                Text(_userProfile!.bio,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              if (_userProfile?.createdAt != null)
                Text(
                    '${languageProvider.currentLanguage == 'ru' ? 'Зарегистрирован' : 'Registered'}: ${_formatDate(_userProfile!.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editProfile,
          ),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.people, color: Color(0xFFDC143C)),
          title: Text(languageProvider.currentLanguage == 'ru'
              ? 'Поиск пользователей'
              : 'User search'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserSearchScreen()),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.logout, color: Color(0xFFDC143C)),
          title: Text(
              languageProvider.currentLanguage == 'ru' ? 'Выйти' : 'Logout'),
          onTap: () => FirebaseAuth.instance.signOut(),
        ),
      ],
    );
  }
}

// ЭКРАН ПОИСКА ПОЛЬЗОВАТЕЛЕЙ
class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  List<UserProfile> _users = [];
  List<UserProfile> _filteredUsers = [];
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _users;
      });
    } else {
      setState(() {
        _filteredUsers = _users
            .where((user) =>
                user.username.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final users = snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => UserProfile.fromMap(doc.data()))
          .toList();

      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки пользователей: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createChatWithUser(UserProfile user) async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      final chatDoc = FirebaseFirestore.instance.collection('chats').doc();
      await chatDoc.set({
        'id': chatDoc.id,
        'name': user.username,
        'participants': [currentUserId, user.userId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': languageProvider.currentLanguage == 'ru'
            ? 'Чат создан'
            : 'Chat created',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {currentUserId: 0, user.userId: 1},
        'type': 'direct',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${languageProvider.currentLanguage == 'ru' ? 'Чат с' : 'Chat with'} ${user.username} ${languageProvider.currentLanguage == 'ru' ? 'создан' : 'created'}')),
      );
    } catch (e) {
      print('Ошибка создания чата: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(languageProvider.currentLanguage == 'ru'
                ? 'Ошибка создания чата'
                : 'Error creating chat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: languageProvider.currentLanguage == 'ru'
                ? 'Поиск пользователей...'
                : 'Search users...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF8B0000),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _filteredUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                          languageProvider.currentLanguage == 'ru'
                              ? 'Пользователи не найдены'
                              : 'Users not found',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFFDC143C),
                        child: user.avatarUrl.isNotEmpty
                            ? ClipOval(child: Image.network(user.avatarUrl))
                            : Text(user.username[0].toUpperCase(),
                                style: TextStyle(color: Colors.white)),
                      ),
                      title: Text(user.username),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.email),
                          if (user.bio.isNotEmpty)
                            Text(user.bio,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      trailing: Icon(Icons.chat, color: Color(0xFFDC143C)),
                      onTap: () => _createChatWithUser(user),
                    );
                  },
                ),
    );
  }
}

// ЭКРАН ЧАТА С РЕАЛЬНЫМ ВРЕМЕНЕМ
class ChatScreen extends StatefulWidget {
  final Chat chat;
  const ChatScreen({super.key, required this.chat});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _setTypingStatus(false);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ФИЧА #9 - СТАТУСЫ НАБОРА
  void _setTypingStatus(bool isTyping) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
      'typingStatus': isTyping ? 'typing' : null,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  void _onTextChanged(String text) {
    _typingTimer?.cancel();
    _setTypingStatus(true);

    _typingTimer = Timer(Duration(seconds: 2), () {
      _setTypingStatus(false);
    });
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id)
          .collection('messages')
          .add({
        'text': _messageController.text,
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'isRead': false, // ФИЧА #10 - ПРОЧИТАННЫЕ СООБЩЕНИЯ
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id)
          .update({
        'lastMessage': _messageController.text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      _setTypingStatus(false);
    } catch (e) {
      print('Ошибка отправки сообщения: $e');
    }
  }

  Future<void> _sendImage() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final currentUserId = FirebaseAuth.instance.currentUser!.uid;

        // ФИЧА #9 - СТАТУС ОТПРАВКИ ФОТО
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'typingStatus': 'sending_photo',
        });

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chat.id)
            .collection('messages')
            .add({
          'text': languageProvider.currentLanguage == 'ru'
              ? '📷 [Изображение]'
              : '📷 [Image]',
          'senderId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'image',
          'isRead': false,
        });

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chat.id)
            .update({
          'lastMessage': languageProvider.currentLanguage == 'ru'
              ? '📷 Изображение'
              : '📷 Image',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });

        // СБРОС СТАТУСА
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'typingStatus': null,
        });
      }
    } catch (e) {
      print('Ошибка отправки изображения: $e');
    }
  }

  Future<void> _sendVoiceMessage() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    try {
      // ФИЧА #9 - СТАТУС ОТПРАВКИ ГОЛОСОВОГО
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'typingStatus': 'sending_voice',
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id)
          .collection('messages')
          .add({
        'text': languageProvider.currentLanguage == 'ru'
            ? '🎤 [Голосовое сообщение]'
            : '🎤 [Voice message]',
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'voice',
        'isRead': false,
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id)
          .update({
        'lastMessage': languageProvider.currentLanguage == 'ru'
            ? '🎤 Голосовое сообщение'
            : '🎤 Voice message',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // СБРОС СТАТУСА
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'typingStatus': null,
      });
    } catch (e) {
      print('Ошибка отправки голосового сообщения: $e');
    }
  }

  // ФИЧА #2 - ПРОСМОТР ПРОФИЛЯ ИЗ ЧАТА
  void _viewUserProfile(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final userProfile = UserProfile.fromMap(userDoc.data()!);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(userProfile.username),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFDC143C),
                  child: userProfile.avatarUrl.isNotEmpty
                      ? ClipOval(child: Image.network(userProfile.avatarUrl))
                      : Text(userProfile.username[0].toUpperCase(),
                          style: TextStyle(fontSize: 24, color: Colors.white)),
                ),
                SizedBox(height: 16),
                Text(userProfile.email, style: TextStyle(fontSize: 16)),
                if (userProfile.bio.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(userProfile.bio,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center),
                  ),
                SizedBox(height: 8),
                Text(
                  'Online: ${userProfile.isOnline ? 'Да' : 'Нет'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Закрыть'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Ошибка загрузки профиля: $e');
    }
  }

  Widget _buildMessageContent(Message message) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    switch (message.type) {
      case 'image':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo,
                color: message.isMe ? Colors.white : Colors.black),
            SizedBox(width: 8),
            Text(
                languageProvider.currentLanguage == 'ru'
                    ? '📷 Изображение'
                    : '📷 Image',
                style: TextStyle(
                  fontSize: 16,
                  color: message.isMe ? Colors.white : Colors.black,
                )),
          ],
        );
      case 'voice':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic, color: message.isMe ? Colors.white : Colors.black),
            SizedBox(width: 8),
            Text(
                languageProvider.currentLanguage == 'ru'
                    ? '🎤 Голосовое'
                    : '🎤 Voice',
                style: TextStyle(
                  fontSize: 16,
                  color: message.isMe ? Colors.white : Colors.black,
                )),
          ],
        );
      default:
        return Text(
          message.text,
          style: TextStyle(
            fontSize: 16,
            color: message.isMe ? Colors.white : Colors.black,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            // ФИЧА #2 - ПРОСМОТР ПРОФИЛЯ ПРИ ТАПЕ НА ЗАГОЛОВОК
            final otherUserId = widget.chat.participants
                .firstWhere((id) => id != currentUserId, orElse: () => '');
            if (otherUserId.isNotEmpty) {
              _viewUserProfile(otherUserId);
            }
          },
          child: Row(children: [
            CircleAvatar(
              backgroundColor: Color(0xFFDC143C),
              child: Text(widget.chat.name[0],
                  style: TextStyle(color: Colors.white)),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.chat.name),
                // ФИЧА #9 - СТАТУСЫ В РЕАЛЬНОМ ВРЕМЕНИ
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.chat.participants.firstWhere(
                          (id) => id != currentUserId,
                          orElse: () => ''))
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      final typingStatus = userData?['typingStatus'];
                      final isOnline = userData?['isOnline'] ?? false;

                      if (typingStatus == 'typing') {
                        return Text(
                          languageProvider.currentLanguage == 'ru'
                              ? 'печатает...'
                              : 'typing...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      } else if (typingStatus == 'sending_photo') {
                        return Text(
                          languageProvider.currentLanguage == 'ru'
                              ? 'отправляет фото...'
                              : 'sending photo...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      } else if (typingStatus == 'sending_voice') {
                        return Text(
                          languageProvider.currentLanguage == 'ru'
                              ? 'отправляет голосовое...'
                              : 'sending voice...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      } else {
                        return Text(
                          isOnline
                              ? (languageProvider.currentLanguage == 'ru'
                                  ? 'онлайн'
                                  : 'online')
                              : (languageProvider.currentLanguage == 'ru'
                                  ? 'офлайн'
                                  : 'offline'),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      }
                    }
                    return SizedBox();
                  },
                ),
              ],
            ),
          ]),
        ),
        backgroundColor: Color(0xFF8B0000),
        actions: [
          PopupMenuButton<String>(
            onSelected: (language) => languageProvider.setLanguage(language),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'ru', child: Text('🇷🇺 Русский')),
              PopupMenuItem(value: 'en', child: Text('🇺🇸 English')),
            ],
            icon: Icon(Icons.language, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chat.id)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text(languageProvider.currentLanguage == 'ru'
                            ? 'Ошибка загрузки сообщений'
                            : 'Error loading messages'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final currentUserId =
                        FirebaseAuth.instance.currentUser!.uid;
                    return Message(
                      id: doc.id,
                      text: data['text'] ?? '',
                      isMe: data['senderId'] == currentUserId,
                      time: _formatTime(data['timestamp']),
                      senderId: data['senderId'] ?? '',
                      type: data['type'] ?? 'text',
                      isRead: data['isRead'] ?? false, // ФИЧА #10
                    );
                  }).toList();

                  // ФИЧА #10 - ОТМЕТКА КАК ПРОЧИТАННЫЕ
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    final unreadMessages =
                        messages.where((msg) => !msg.isMe && !msg.isRead);
                    for (final msg in unreadMessages) {
                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(widget.chat.id)
                          .collection('messages')
                          .doc(msg.id)
                          .update({'isRead': true});
                    }
                  });

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return GestureDetector(
                        onTap: () {
                          // ФИЧА #2 - ПРОСМОТР ПРОФИЛЯ ПРИ ТАПЕ НА СООБЩЕНИЕ
                          if (!message.isMe) {
                            _viewUserProfile(message.senderId);
                          }
                        },
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Align(
                            alignment: message.isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: message.isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: message.isMe
                                        ? Color(0xFFDC143C)
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: _buildMessageContent(message),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(message.time,
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    if (message.isMe) ...[
                                      SizedBox(width: 4),
                                      // ФИЧА #10 - ИКОНКИ ПРОЧИТАННЫХ СООБЩЕНИЙ
                                      Icon(
                                        message.isRead
                                            ? Icons.done_all
                                            : Icons.done,
                                        size: 12,
                                        color: message.isRead
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.photo_camera, color: Color(0xFFDC143C)),
                    onPressed: _sendImage,
                  ),
                  IconButton(
                    icon: Icon(Icons.mic, color: Color(0xFFDC143C)),
                    onPressed: _sendVoiceMessage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged:
                          _onTextChanged, // ФИЧА #9 - СЛЕЖЕНИЕ ЗА НАБОРОМ
                      decoration: InputDecoration(
                        hintText: languageProvider.currentLanguage == 'ru'
                            ? 'Написать сообщение...'
                            : 'Write a message...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Color(0xFFDC143C),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Timer? {
  void cancel() {}
}

class Timer {
  Timer(Duration duration, Null Function() param1);
}
