import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // Background handling (no UI)
  }

  static void listenForeground(
      {required void Function(RemoteMessage) onMessage}) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }

  static Future<String?> getToken() => _messaging.getToken();
}
