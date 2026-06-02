import 'package:flutter/material.dart';

/// Виджет для выбора стикеров
class StickerPicker extends StatelessWidget {
  final Function(String stickerId) onStickerSelected;
  final Function()? onDismiss;

  const StickerPicker({
    Key? key,
    required this.onStickerSelected,
    this.onDismiss,
  }) : super(key: key);

  // Локальные стикеры (можно заменить на ассеты или сетевые изображения)
  static const Map<String, String> _stickers = {
    'thumbs_up': '👍',
    'heart': '❤️',
    'fire': '🔥',
    'party': '🎉',
    'rocket': '🚀',
    'star': '⭐',
    'trophy': '🏆',
    'clap': '👏',
    'cool': '😎',
    'wink': '😉',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[700]!, width: 1)),
            ),
            child: Row(
              children: [
                Text(
                  'Стикеры',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
          // Сетка стикеров
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _stickers.length,
              itemBuilder: (context, index) {
                final stickerEntry = _stickers.entries.elementAt(index);
                return GestureDetector(
                  onTap: () {
                    onStickerSelected(stickerEntry.key);
                    if (onDismiss != null) onDismiss!();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        stickerEntry.value,
                        style: TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

