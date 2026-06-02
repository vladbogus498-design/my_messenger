import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/biometric_service.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _biometricEnabled = false;
  String _selfDestructTimer = '5 минут';
  bool _loading = true;

  static const _timerOptions = <String>[
    '5 минут',
    '1 час',
    '1 день',
    '1 неделя',
    'Отключено',
  ];

  @override
  void initState() {
    super.initState();
    _restorePrefs();
  }

  Future<void> _restorePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool('useBiometric') ?? false;
      _selfDestructTimer = prefs.getString('selfDestructTimer') ?? '5 минут';
      _loading = false;
    });
  }

  Future<void> _updateBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      final canAuth = await BiometricService.canAuthenticate();
      if (!canAuth) {
        _showSnack('Биометрия недоступна на этом устройстве');
        return;
      }
      final success = await BiometricService.authenticate(
        reason: 'Войдите по отпечатку, чтобы включить быстрый вход',
      );
      if (!success) {
        _showSnack('Не удалось подтвердить личность');
        return;
      }
      await prefs.setBool('useBiometric', true);
      setState(() => _biometricEnabled = true);
      _showSnack('Биометрический вход включён');
    } else {
      await prefs.setBool('useBiometric', false);
      setState(() => _biometricEnabled = false);
      _showSnack('Биометрический вход отключён');
    }
  }

  Future<void> _pickTimer() async {
    final theme = Theme.of(context);
    final prefs = await SharedPreferences.getInstance();
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Таймер самоуничтожения',
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 12),
          ..._timerOptions.map(
            (option) => ListTile(
              title: Text(option),
              trailing: option == _selfDestructTimer
                  ? Icon(Icons.check,
                      color: theme.colorScheme.primary, size: 20)
                  : null,
              onTap: () => Navigator.of(ctx).pop(option),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
    if (selected != null && selected != _selfDestructTimer) {
      await prefs.setString('selfDestructTimer', selected);
      setState(() => _selfDestructTimer = selected);
    }
  }

  Future<void> _showLogoutDialog() async {
    final theme = Theme.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text(
          'После выхода потребуется повторная авторизация.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ОСТАТЬСЯ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ВЫЙТИ'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = _user;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                _HeaderSection(
                  user: user,
                  onThemeSwitch: () {
                    themeNotifier.toggleTheme();
                  },
                  themeMode: themeMode,
                ),
                const SizedBox(height: 32),
                _SectionCard(
                  title: 'Внешний вид',
                  children: [
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Тёмная'),
                          icon: Icon(Icons.dark_mode),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Светлая'),
                          icon: Icon(Icons.light_mode),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Система'),
                          icon: Icon(Icons.auto_mode),
                        ),
                      ],
                      selected: <ThemeMode>{themeMode},
                      onSelectionChanged: (values) {
                        final mode = values.first;
                        themeNotifier.setThemeMode(mode);
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith(
                          (states) => states.contains(MaterialState.selected)
                              ? colorScheme.primary
                              : colorScheme.surfaceVariant,
                        ),
                        foregroundColor: MaterialStateProperty.resolveWith(
                          (states) => states.contains(MaterialState.selected)
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Приватность',
                  children: [
                    SwitchListTile(
                      value: _biometricEnabled,
                      onChanged: _updateBiometric,
                      title: const Text('Использовать вход по отпечатку'),
                      subtitle: const Text(
                          'Сканер отпечатка или лица при запуске приложения'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: const Text('Таймер самоуничтожения'),
                      subtitle: Text(_selfDestructTimer),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickTimer,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Аккаунт',
                  children: [
                    ListTile(
                      leading: Icon(Icons.logout_rounded,
                          color: colorScheme.error),
                      title: Text(
                        'Выйти из аккаунта',
                        style: TextStyle(color: colorScheme.error),
                      ),
                      onTap: _showLogoutDialog,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.user,
    required this.onThemeSwitch,
    required this.themeMode,
  });

  final User? user;
  final VoidCallback onThemeSwitch;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initials = (user?.email ?? user?.displayName ?? 'u').isNotEmpty
        ? (user?.email ?? user?.displayName ?? 'u').substring(0, 1).toUpperCase()
        : 'U';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: colorScheme.secondary.withOpacity(0.2),
          child: Text(
            initials,
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: colorScheme.secondary),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.email ?? 'Профиль',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.uid ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onThemeSwitch,
          tooltip: 'Переключить тему',
          icon: Text(
            themeMode == ThemeMode.dark ? '🌙' : '☀️',
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}


