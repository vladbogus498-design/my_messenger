import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final String? chatId; // optional per-chat settings
  const NotificationSettingsScreen({Key? key, this.chatId}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _enabled = true;
  bool _mentionsOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final prefix = widget.chatId != null ? 'chat_${widget.chatId}_' : '';
    setState(() {
      _enabled = p.getBool('${prefix}notif_enabled') ?? true;
      _mentionsOnly = p.getBool('${prefix}notif_mentions_only') ?? false;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    final prefix = widget.chatId != null ? 'chat_${widget.chatId}_' : '';
    await p.setBool('${prefix}notif_enabled', _enabled);
    await p.setBool('${prefix}notif_mentions_only', _mentionsOnly);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Настройки уведомлений')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Уведомления включены'),
            value: _enabled,
            onChanged: (v) {
              setState(() => _enabled = v);
              _save();
            },
          ),
          SwitchListTile(
            title: Text('@Упоминания только'),
            value: _mentionsOnly,
            onChanged: (v) {
              setState(() => _mentionsOnly = v);
              _save();
            },
          ),
        ],
      ),
    );
  }
}
