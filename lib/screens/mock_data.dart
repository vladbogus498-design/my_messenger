// lib/screens/mock_data.dart
import 'package:flutter/material.dart';

enum ChatType { personal, group, channel }

class MockMessage {
  final String text;
  final bool isMe;
  final DateTime time;

  MockMessage({required this.text, required this.isMe, required this.time});
}

class MockChat {
  final String id;
  final String name;
  final String avatarEmoji;
  final Color avatarColor;
  final ChatType type;
  String lastMessage;
  DateTime lastMessageTime;
  int unreadCount;
  bool isSubscribed; // для групп/каналов — ты подписан или нет

  MockChat({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.avatarColor,
    required this.type,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isSubscribed = true,
  });
}

// ─── Глобальное хранилище сообщений ─────────────────────────────────────────
final Map<String, List<MockMessage>> chatMessages = {
  '1': [
    MockMessage(text: 'Привет!', isMe: false, time: DateTime.now().subtract(Duration(minutes: 30))),
    MockMessage(text: 'Как дела?', isMe: false, time: DateTime.now().subtract(Duration(minutes: 29))),
    MockMessage(text: 'Всё отлично, работаю над проектом 🔥', isMe: true, time: DateTime.now().subtract(Duration(minutes: 28))),
    MockMessage(text: 'Darkkick выглядит огонь!', isMe: false, time: DateTime.now().subtract(Duration(minutes: 25))),
    MockMessage(text: 'Спасибо, стараюсь 😎', isMe: true, time: DateTime.now().subtract(Duration(minutes: 20))),
  ],
  '2': [
    MockMessage(text: 'Отправил код 👍', isMe: false, time: DateTime.now().subtract(Duration(hours: 3))),
    MockMessage(text: 'Получил, смотрю', isMe: true, time: DateTime.now().subtract(Duration(hours: 2, minutes: 55))),
    MockMessage(text: 'Всё работает?', isMe: false, time: DateTime.now().subtract(Duration(hours: 2, minutes: 50))),
    MockMessage(text: 'Да, всё ок 👌', isMe: true, time: DateTime.now().subtract(Duration(hours: 2, minutes: 45))),
    MockMessage(text: 'скинул файл', isMe: false, time: DateTime.now().subtract(Duration(hours: 2, minutes: 40))),
  ],
  '3': [
    MockMessage(text: 'Ребята, как проект?', isMe: false, time: DateTime.now().subtract(Duration(days: 1, hours: 2))),
    MockMessage(text: 'Идёт по плану', isMe: true, time: DateTime.now().subtract(Duration(days: 1, hours: 1))),
    MockMessage(text: 'Спасибо за помощь!', isMe: false, time: DateTime.now().subtract(Duration(days: 1))),
  ],
  '4': [
    MockMessage(text: 'Когда готово?', isMe: false, time: DateTime.now().subtract(Duration(days: 2))),
    MockMessage(text: 'Скоро, дорабатываю', isMe: true, time: DateTime.now().subtract(Duration(days: 1, hours: 23))),
  ],
  '5': [
    MockMessage(text: 'Классная идея! 🚀', isMe: false, time: DateTime.now().subtract(Duration(days: 3))),
    MockMessage(text: 'Точно реализуем', isMe: true, time: DateTime.now().subtract(Duration(days: 2, hours: 23))),
  ],
  '6': [
    MockMessage(text: 'Новый релиз уже завтра 🚀', isMe: false, time: DateTime.now().subtract(Duration(hours: 5))),
    MockMessage(text: 'Финальная версия 🔥', isMe: false, time: DateTime.now().subtract(Duration(hours: 4))),
  ],
  '7': [
    MockMessage(text: 'Подписывайтесь на канал!', isMe: false, time: DateTime.now().subtract(Duration(days: 1))),
    MockMessage(text: 'Обновление v2.0 уже в сторе', isMe: false, time: DateTime.now().subtract(Duration(hours: 12))),
  ],
};

// ─── Список чатов ────────────────────────────────────────────────────────────
final List<MockChat> allChats = [
  // Личные
  MockChat(
    id: '1', name: 'Dark', avatarEmoji: '😈',
    avatarColor: Color(0xFF4A148C), type: ChatType.personal,
    lastMessage: 'Спасибо, стараюсь 😎',
    lastMessageTime: DateTime.now().subtract(Duration(minutes: 20)), unreadCount: 2,
  ),
  MockChat(
    id: '2', name: 'void.exe', avatarEmoji: '💻',
    avatarColor: Color(0xFF1A237E), type: ChatType.personal,
    lastMessage: 'скинул файл',
    lastMessageTime: DateTime.now().subtract(Duration(hours: 2, minutes: 40)), unreadCount: 1,
  ),
  MockChat(
    id: '4', name: 'Nox', avatarEmoji: '🌙',
    avatarColor: Color(0xFF006064), type: ChatType.personal,
    lastMessage: 'Скоро, дорабатываю',
    lastMessageTime: DateTime.now().subtract(Duration(days: 1, hours: 23)),
  ),
  MockChat(
    id: '5', name: 'Dreamer', avatarEmoji: '✨',
    avatarColor: Color(0xFF880E4F), type: ChatType.personal,
    lastMessage: 'Классная идея! 🚀',
    lastMessageTime: DateTime.now().subtract(Duration(days: 3)),
  ),
  // Группы — ты создатель (isSubscribed=true означает ты в группе/ты создатель)
  MockChat(
    id: '3', name: 'Night Squad ⚡', avatarEmoji: '👥',
    avatarColor: Color(0xFF37474F), type: ChatType.group,
    lastMessage: 'Спасибо за помощь!',
    lastMessageTime: DateTime.now().subtract(Duration(days: 1)),
    unreadCount: 3, isSubscribed: true,
  ),
  MockChat(
    id: '6', name: 'Тёмный код 💫', avatarEmoji: '🖤',
    avatarColor: Color(0xFF212121), type: ChatType.group,
    lastMessage: 'Финальная версия 🔥',
    lastMessageTime: DateTime.now().subtract(Duration(hours: 4)),
    isSubscribed: false, // чужая группа — можно вступить
  ),
  // Каналы
  MockChat(
    id: '7', name: 'DarkKick Official', avatarEmoji: '📢',
    avatarColor: Color(0xFF6A1B9A), type: ChatType.channel,
    lastMessage: 'Обновление v2.0 уже в сторе',
    lastMessageTime: DateTime.now().subtract(Duration(hours: 12)),
    isSubscribed: true, // ты создатель канала
  ),
];
