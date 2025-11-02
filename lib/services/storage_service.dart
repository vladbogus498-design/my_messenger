import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Загрузка изображения чата
  static Future<String> uploadChatImage(File imageFile, String chatId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat_$chatId/${userId}_$timestamp.jpg';
      final ref = _storage.ref().child(fileName);

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('❌ Ошибка загрузки изображения чата: $e');
      rethrow;
    }
  }

  // Загрузка аватара пользователя
  static Future<String> uploadUserAvatar(File imageFile) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final fileName = 'avatars/$userId.jpg';
      final ref = _storage.ref().child(fileName);

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('❌ Ошибка загрузки аватара: $e');
      rethrow;
    }
  }

  // Удаление аватара
  static Future<void> deleteUserAvatar() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final fileName = 'avatars/$userId.jpg';
      final ref = _storage.ref().child(fileName);
      await ref.delete();
    } catch (e) {
      print('❌ Ошибка удаления аватара: $e');
    }
  }
}
