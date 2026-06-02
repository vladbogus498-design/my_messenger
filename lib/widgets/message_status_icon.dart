import 'package:flutter/material.dart';

/// Виджет для отображения статуса сообщения
class MessageStatusIcon extends StatelessWidget {
  final String status;
  final bool isOwnMessage;
  final double size;

  const MessageStatusIcon({
    Key? key,
    required this.status,
    required this.isOwnMessage,
    this.size = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isOwnMessage) {
      return const SizedBox.shrink();
    }

    IconData iconData;
    Color iconColor;

    switch (status) {
      case 'sending':
        iconData = Icons.access_time;
        iconColor = Colors.grey;
        break;
      case 'sent':
        iconData = Icons.check;
        iconColor = Colors.grey;
        break;
      case 'delivered':
        iconData = Icons.done_all;
        iconColor = Colors.grey;
        break;
      case 'read':
        iconData = Icons.done_all;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.access_time;
        iconColor = Colors.grey;
    }

    return Icon(
      iconData,
      size: size,
      color: iconColor,
    );
  }
}

