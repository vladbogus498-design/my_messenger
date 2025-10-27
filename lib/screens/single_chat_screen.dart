import 'package:flutter/material.dart';

class SingleChatScreen extends StatelessWidget {
  final String chatId;
  final String chatName;

  SingleChatScreen({required this.chatId, required this.chatName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(chatName),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.grey[900],
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'Чат "$chatName"\n\nЗдесь будут сообщения',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
