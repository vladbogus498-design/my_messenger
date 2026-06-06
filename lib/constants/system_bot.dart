import '../models/chat.dart';

// ignore: constant_identifier_names
const String SYSTEM_BOT_UID = 'darkkick_bot';

class SystemBot {
  const SystemBot._();

  static const uid = SYSTEM_BOT_UID;
  static const name = 'DARKKICK';
  static const tag = 'darkkick';
  static const bio = 'Официальный бот DARKKICK';
  static const welcomeMessage = 'Добро пожаловать в DARKKICK 🖤';
  static const avatarAsset = 'assets/images/auth_angel.png';
  static const type = 'system';

  static String chatIdFor(String userId) => 'system_darkkick_$userId';

  static bool isSystemChat(Chat chat) {
    return chat.type.toLowerCase().trim() == type &&
        chat.participants.contains(uid);
  }

  static List<String> get searchKeywords {
    const values = ['darkkick', 'dark', 'kick', 'darkk', 'darkki'];
    final prefixes = <String>{};
    for (final value in values) {
      for (var i = 1; i <= value.length; i++) {
        prefixes.add(value.substring(0, i));
      }
    }
    prefixes.addAll(values);
    return prefixes.toList();
  }
}
