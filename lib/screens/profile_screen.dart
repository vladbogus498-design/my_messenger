import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart' as legacy_provider;
import '../services/theme_service.dart';
import '../services/biometric_service.dart';
import 'theme_preview_screen.dart';
import 'user_search_screen.dart';
import 'group_create_screen.dart';
import 'notification_settings_screen.dart';
import 'user_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _darkTheme = true;
  bool _notifications = true;
  bool _privacyMode = true;
  String _selfDestructTimer = '5 seconds';
  String _userStatus = 'Online';

  String _selectedTheme = 'purple';
  Map<String, Color> _themeColors = {
    'purple': Colors.deepPurple,
    'blue': Colors.blueAccent,
    'red': Colors.redAccent,
    'green': Colors.green,
    'orange': Colors.orange,
  };

  bool _invisibleMode = false;
  bool _useBiometric = false;
  bool _amoledTheme = false;

  final List<String> _timerOptions = [
    '5 seconds',
    '1 minute',
    '1 hour',
    '1 day',
    '1 week'
  ];
  final List<String> _statusOptions = [
    'Online',
    'Busy',
    'Away',
    'Invisible',
    'Do Not Disturb'
  ];

  Color get _mainColor => _themeColors[_selectedTheme] ?? Colors.deepPurple;
  Color get _backgroundColor => _amoledTheme ? Colors.black : Colors.grey[900]!;
  Color get _cardColor => _amoledTheme ? Colors.grey[900]! : Colors.grey[800]!;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getString('selectedTheme') ?? 'purple';
      _amoledTheme = prefs.getBool('amoledTheme') ?? false;
      _userStatus = prefs.getString('userStatus') ?? 'Online';
      _invisibleMode = prefs.getBool('invisibleMode') ?? false;
      _useBiometric = prefs.getBool('useBiometric') ?? false;
      _selfDestructTimer = prefs.getString('selfDestructTimer') ?? '5 seconds';
      _darkTheme = prefs.getBool('darkTheme') ?? true;
      _notifications = prefs.getBool('notifications') ?? true;
      _privacyMode = prefs.getBool('privacyMode') ?? true;
    });
  }

  void _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
    print('✅ Saved setting: $key = $value');
  }

  void _logout() async {
    try {
      // Закрываем все слушатели перед выходом
      // (слушатели будут закрыты автоматически при dispose провайдеров)
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  void _openMyProfile() {
    final userId = _user?.uid;
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            userId: userId,
            isMyProfile: true,
          ),
        ),
      );
    }
  }

  void _showThemeSelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text('Выбрать цвет темы', style: TextStyle(color: Colors.white)),
        contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
        content: Container(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _themeColors.length,
            itemBuilder: (context, index) {
              final colorKey = _themeColors.keys.elementAt(index);
              final color = _themeColors[colorKey]!;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedTheme = colorKey);
                  _saveSetting('selectedTheme', colorKey);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                    border: _selectedTheme == colorKey
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: _selectedTheme == colorKey
                      ? Icon(Icons.check, color: Colors.white, size: 30)
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ОТМЕНА', style: TextStyle(color: _mainColor)),
          ),
        ],
      ),
    );
  }

  void _testBiometric() async {
    final canAuthenticate = await BiometricService.canAuthenticate();
    if (!canAuthenticate) {
      _showMessage(
          'Биометрия недоступна на этом устройстве\nПроверьте настройки безопасности');
      return;
    }

    final biometricName = await BiometricService.getBiometricTypeName();
    final authenticated = await BiometricService.authenticate();

    if (authenticated) {
      _showMessage('$biometricName: Успешно! ✅');
    } else {
      _showMessage(
          'Аутентификация не удалась ❌\nОтменено пользователем или ошибка');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _mainColor,
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (_invisibleMode) return Colors.grey;

    switch (status) {
      case 'Online':
        return Colors.green;
      case 'Busy':
        return Colors.orange;
      case 'Away':
        return Colors.yellow;
      case 'Invisible':
        return Colors.grey;
      case 'Do Not Disturb':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Online':
        return Icons.circle;
      case 'Busy':
        return Icons.work;
      case 'Away':
        return Icons.access_time;
      case 'Invisible':
        return Icons.visibility_off;
      case 'Do Not Disturb':
        return Icons.notifications_off;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStatusColor = _getStatusColor(_userStatus);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final themeService = legacy_provider.Provider.of<ThemeService>(context);
    final isDarkTheme = themeService.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: isMobile ? 20 : 40),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: IconButton(
                    key: ValueKey(isDarkTheme),
                    icon: Text(
                      isDarkTheme ? '🌙' : '☀️',
                      style: TextStyle(fontSize: isMobile ? 20 : 22),
                    ),
                    tooltip: isDarkTheme
                        ? 'Включить светлую тему'
                        : 'Включить тёмную тему',
                    onPressed: () => themeService.toggleTheme(),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _openMyProfile,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: isMobile ? 45 : 50,
                    backgroundColor: _mainColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: TextStyle(
                            fontSize: isMobile ? 32 : 36,
                            color: Colors.white,
                          ),
                        ),
                        if (!isMobile)
                          Text(
                            'Tap to edit',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 8),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: isMobile ? 16 : 18,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.edit,
                        size: isMobile ? 18 : 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              _user?.email ?? 'Unknown User',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getStatusIcon(_userStatus),
                      color: currentStatusColor, size: 16),
                  SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _userStatus,
                    dropdownColor: _cardColor,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    underline: Container(),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                    onChanged: (value) {
                      setState(() => _userStatus = value!);
                      _saveSetting('userStatus', value);
                    },
                    items: _statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Row(
                          children: [
                            Icon(_getStatusIcon(status),
                                color: _getStatusColor(status), size: 16),
                            SizedBox(width: 8),
                            Text(status),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Member since: ${DateTime.now().toString().substring(0, 10)}',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(height: isMobile ? 20 : 30),
            _buildInfoCard(
              title: 'ИНФОРМАЦИЯ ОБ АККАУНТЕ',
              children: [
                _buildInfoRow(
                    'ID пользователя', _user?.uid.substring(0, 8) ?? 'Unknown'),
                _buildInfoRow('Email подтвержден',
                    _user?.emailVerified == true ? 'Да' : 'Нет'),
                _buildInfoRow('Тип аккаунта', 'Стандартный'),
                _buildInfoRow('Использовано хранилища', '15% из 1GB'),
                _buildInfoRow('Текущий статус', _userStatus),
                _buildInfoRow('Цвет темы', _selectedTheme.toUpperCase()),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 20),
            _buildInfoCard(
              title: 'ПРИВАТНОСТЬ И НАСТРОЙКИ',
              children: [
                _buildSwitchRow(
                  'Биометрический замок',
                  'Используйте отпечаток/лицо для разблокировки',
                  _useBiometric,
                  (value) async {
                    if (value) {
                      final canAuth = await BiometricService.canAuthenticate();
                      if (canAuth) {
                        final authenticated =
                            await BiometricService.authenticate();
                        if (authenticated) {
                          setState(() => _useBiometric = true);
                          _saveSetting('useBiometric', true);
                          final biometricName =
                              await BiometricService.getBiometricTypeName();
                          _showMessage('$biometricName включен! 🔐');
                        } else {
                          _showMessage('Аутентификация не удалась');
                        }
                      } else {
                        _showMessage('Биометрия недоступна на этом устройстве');
                      }
                    } else {
                      setState(() => _useBiometric = false);
                      _saveSetting('useBiometric', false);
                      _showMessage('Биометрический замок отключен');
                    }
                  },
                ),
                _buildSwitchRow(
                  'AMOLED черная тема',
                  'Настоящий черный для OLED экранов',
                  _amoledTheme,
                  (value) {
                    setState(() => _amoledTheme = value);
                    _saveSetting('amoledTheme', value);
                  },
                ),
                _buildSwitchRow(
                  'Невидимый режим',
                  'Скрыть ваш статус онлайн от всех',
                  _invisibleMode,
                  (value) {
                    setState(() => _invisibleMode = value);
                    _saveSetting('invisibleMode', value);
                  },
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
                  child: Row(
                    children: [
                      Icon(Icons.timer,
                          color: _mainColor, size: isMobile ? 18 : 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Таймер самоуничтожения',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selfDestructTimer,
                        dropdownColor: _cardColor,
                        style: TextStyle(
                            color: Colors.white, fontSize: isMobile ? 11 : 12),
                        onChanged: (value) {
                          setState(() => _selfDestructTimer = value!);
                          _saveSetting('selfDestructTimer', value);
                        },
                        items: _timerOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                _buildSwitchRow(
                  'Режим приватности',
                  'Скрыть статус набора',
                  _privacyMode,
                  (value) {
                    setState(() => _privacyMode = value);
                    _saveSetting('privacyMode', value);
                  },
                ),
                _buildSwitchRow(
                  'Темная тема',
                  'Всегда темная',
                  _darkTheme,
                  (value) {
                    setState(() => _darkTheme = value);
                    _saveSetting('darkTheme', value);
                  },
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => legacy_provider.Provider.of<ThemeService>(context, listen: false).setThemeMode(ThemeMode.dark),
                          icon: Icon(Icons.dark_mode),
                          label: Text('ТЁМНАЯ'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => legacy_provider.Provider.of<ThemeService>(context, listen: false).setThemeMode(ThemeMode.light),
                          icon: Icon(Icons.light_mode),
                          label: Text('СВЕТЛАЯ'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => legacy_provider.Provider.of<ThemeService>(context, listen: false).toggleTheme(),
                          icon: Icon(Icons.brightness_auto),
                          label: Text('ПЕРЕКЛЮЧИТЬ'),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSwitchRow(
                  'Уведомления',
                  'Оповещения о сообщениях',
                  _notifications,
                  (value) {
                    setState(() => _notifications = value);
                    _saveSetting('notifications', value);
                  },
                ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 20),
            _buildInfoCard(
              title: 'ВАША СТАТИСТИКА',
              children: [
                _buildStatRow('Чатов создано', '12', Icons.chat),
                _buildStatRow('Сообщений отправлено', '47', Icons.message),
                _buildStatRow('Самоуничтожено', '23', Icons.auto_delete),
                _buildStatRow('Оценка приватности', '98%', Icons.security),
              ],
            ),
            SizedBox(height: isMobile ? 20 : 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showThemeSelector,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mainColor,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                    ),
                    child: Text(
                      'ИЗМЕНИТЬ ТЕМУ',
                      style: TextStyle(fontSize: isMobile ? 13 : 14),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                    ),
                    child: Text(
                      'ВЫХОД',
                      style: TextStyle(fontSize: isMobile ? 13 : 14),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ThemePreviewScreen()),
                  );
                },
                child: Text('ПРЕДПРОСМОТР ТЕМЫ'),
              ),
            ),
            SizedBox(height: isMobile ? 10 : 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testBiometric,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fingerprint, size: isMobile ? 18 : 20),
                    SizedBox(width: 8),
                    Text(
                      'ТЕСТ БИОМЕТРИИ',
                      style: TextStyle(fontSize: isMobile ? 13 : 14),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _QuickActionButton(
                  icon: Icons.search_rounded,
                  label: 'Поиск',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => UserSearchScreen()),
                  ),
                ),
                _QuickActionButton(
                  icon: Icons.group_add_rounded,
                  label: 'Создать группу',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => GroupCreateScreen()),
                  ),
                ),
                _QuickActionButton(
                  icon: Icons.palette_outlined,
                  label: 'Темы',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ThemePreviewScreen()),
                  ),
                ),
                _QuickActionButton(
                  icon: Icons.notifications_active_outlined,
                  label: 'Уведомления',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => NotificationSettingsScreen()),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'DarkKick v1.0.0 • Messages that leave no trace',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Card(
      color: _cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: _mainColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$label:', style: TextStyle(color: Colors.grey, fontSize: 14)),
          SizedBox(width: 8),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: isMobile ? 11 : 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _mainColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: _mainColor, size: 16),
          SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
          Spacer(),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 170,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          foregroundColor: Colors.white,
          side: BorderSide(color: theme.colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
