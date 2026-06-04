import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/providers/core_providers.dart';
import '../providers/chats_provider.dart';
import '../providers/messages_provider.dart';
import '../services/user_service.dart';
import '../theme/darkkick_colors.dart';
import '../utils/navigation_animations.dart';
import 'account_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  void _openAccount(BuildContext context) {
    Navigator.push(
      context,
      NavigationAnimations.slideFadeRoute(const AccountSettingsScreen()),
    );
  }

  void _showStub(BuildContext context, String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title скоро появится')));
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    ref.invalidate(chatsProvider);
    ref.invalidate(chatsNotifierProvider);
    ref.invalidate(messagesProvider);
    try {
      final localDataSource = await ref.read(localDataSourceProvider.future);
      await localDataSource.clear();
    } catch (_) {
      // Local cache may be unavailable on some builds; provider reset still protects UI state.
    }
    await UserService.setPresence(isOnline: false);
    await FirebaseAuth.instance.signOut();
    ref.invalidate(chatsProvider);
    ref.invalidate(chatsNotifierProvider);
    ref.invalidate(messagesProvider);
    navigator.pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DarkKickColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DarkKickColors.darkBackground,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Настройки',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.account_circle_outlined,
                  title: 'Аккаунт',
                  subtitle: 'Имя, тег и данные аккаунта',
                  onTap: () => _openAccount(context),
                ),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Конфиденциальность',
                  onTap: () => _showStub(context, 'Конфиденциальность'),
                ),
                _SettingsTile(
                  icon: Icons.notifications_none,
                  title: 'Уведомления',
                  onTap: () => _showStub(context, 'Уведомления'),
                ),
                _SettingsTile(
                  icon: Icons.storage_outlined,
                  title: 'Данные и память',
                  onTap: () => _showStub(context, 'Данные и память'),
                ),
                _SettingsTile(
                  icon: Icons.brush_outlined,
                  title: 'Оформление',
                  onTap: () => _showStub(context, 'Оформление'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Помощь',
                  onTap: () => _showStub(context, 'Помощь'),
                ),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'О приложении',
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _LogoutTile(onTap: () => _signOut(context, ref)),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DarkKickColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Darkkick',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Тёмный приватный мессенджер с фиолетовым glow и личными чатами.',
                  style: TextStyle(
                    color: DarkKickColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DarkKickColors.divider),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(
                height: 1,
                indent: 54,
                color: DarkKickColors.divider,
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 28,
      leading: Icon(icon, color: DarkKickColors.textSecondary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(
                color: DarkKickColors.textTertiary,
                fontSize: 12,
              ),
            ),
      trailing: const Icon(
        Icons.chevron_right,
        color: DarkKickColors.textTertiary,
      ),
      onTap: onTap,
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          decoration: BoxDecoration(
            color: DarkKickColors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF44202A)),
          ),
          child: const Row(
            children: [
              Icon(Icons.logout, color: Color(0xFFFF4D5D)),
              SizedBox(width: 14),
              Text(
                'Выйти из аккаунта',
                style: TextStyle(
                  color: Color(0xFFFF4D5D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
