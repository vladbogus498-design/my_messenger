import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/bot_config.dart';
import '../utils/logger.dart';

/// Сервис для управления официальным ботом
class BotService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создает профиль бота в Firestore если его еще нет
  static Future<void> ensureBotExists() async {
    try {
      final botDoc = await _firestore
          .collection('users')
          .doc(BotConfig.officialBotId)
          .get();

      if (!botDoc.exists) {
        await _firestore.collection('users').doc(BotConfig.officialBotId).set({
          'uid': BotConfig.officialBotId,
          'email': BotConfig.botEmail,
          'name': BotConfig.botName,
          'bio': BotConfig.botDescription,
          'photoURL': BotConfig.botAvatarUrl,
          'isBot': true,
          'isVerified': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        appLogger.i('Official bot profile created in Firestore');
      } else {
        appLogger.d('Official bot profile already exists');
      }
    } catch (e) {
      appLogger.e('Error ensuring bot exists', error: e);
    }
  }
}


