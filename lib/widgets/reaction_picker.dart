import 'package:flutter/material.dart';

/// Виджет для выбора реакции (эмодзи)
class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onReactionSelected;
  final Function()? onDismiss;

  const ReactionPicker({
    Key? key,
    required this.onReactionSelected,
    this.onDismiss,
  }) : super(key: key);

  static const List<String> _defaultReactions = [
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
    '👍',
    '👎',
    '🎉',
    '🔥',
    '💯',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _defaultReactions.map((emoji) {
          return GestureDetector(
            onTap: () {
              onReactionSelected(emoji);
              if (onDismiss != null) onDismiss!();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                emoji,
                style: TextStyle(fontSize: 24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

