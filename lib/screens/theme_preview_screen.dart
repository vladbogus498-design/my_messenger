import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy_provider;
import '../services/theme_service.dart';

class ThemePreviewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeService = legacy_provider.Provider.of<ThemeService>(context);
    final keys = themeService.availableKeys;

    return Scaffold(
      appBar: AppBar(title: Text('Предпросмотр темы')),
      body: Column(
        children: [
          Expanded(
            child: _ChatPreview(),
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: keys.map((k) {
                  final selected = k == themeService.currentKey;
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: selected,
                      label: Text(k),
                      onSelected: (_) => themeService.setTheme(k),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(12),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _bubble(context, 'Привет! Это предпросмотр чата.', false),
        ),
        SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: _bubble(context, 'Отлично! Тема применяется мгновенно.', true),
        ),
        SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: _bubble(context, 'Попробуй другие темы ниже.', false),
        ),
      ],
    );
  }

  Widget _bubble(BuildContext context, String text, bool mine) {
    final bg = mine ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor;
    final fg = mine ? Colors.white : Colors.white;
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: fg)),
    );
  }
}


