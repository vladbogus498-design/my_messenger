import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import '../theme/darkkick_colors.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  Future<void> _sendPasswordReset(BuildContext context, String email) async {
    if (email.trim().isEmpty) {
      _showMessage(context, 'Email не указан');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      _showMessage(context, 'Письмо для смены пароля отправлено');
    } catch (error) {
      _showMessage(context, 'Не удалось отправить письмо: $error');
    }
  }

  void _showDeleteStub(BuildContext context) {
    _showMessage(
      context,
      'Удаление аккаунта появится после проверки безопасности',
    );
  }

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    final uid = authUser?.uid;

    return Scaffold(
      backgroundColor: DarkKickColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DarkKickColors.darkBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Аккаунт',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: uid == null
          ? const Center(
              child: Text(
                'Аккаунт не найден',
                style: TextStyle(color: DarkKickColors.textSecondary),
              ),
            )
          : StreamBuilder<UserModel?>(
              stream: UserService.watchUserData(uid),
              builder: (context, snapshot) {
                final user =
                    snapshot.data ??
                    UserModel(
                      uid: uid,
                      email: authUser?.email ?? '',
                      name:
                          authUser?.displayName ??
                          authUser?.email?.split('@').first ??
                          'Пользователь',
                      photoURL: authUser?.photoURL,
                    );
                final tag = (user.username ?? user.tag ?? '').trim();

                return SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    children: [
                      _AccountGroup(
                        children: [
                          _AccountInfoTile(
                            icon: Icons.badge_outlined,
                            title: 'Имя',
                            value: user.name,
                          ),
                          _AccountInfoTile(
                            icon: Icons.alternate_email,
                            title: 'Username / Tag',
                            value: tag.isEmpty ? 'Не указан' : tag,
                          ),
                          _AccountInfoTile(
                            icon: Icons.mail_outline,
                            title: 'Email',
                            value: user.email.isEmpty
                                ? 'Не указан'
                                : user.email,
                          ),
                          _AccountActionTile(
                            icon: Icons.lock_outline,
                            title: 'Пароль',
                            subtitle: 'Отправить письмо для смены пароля',
                            onTap: () =>
                                _sendPasswordReset(context, user.email),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _DeleteAccountTile(onTap: () => _showDeleteStub(context)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _AccountGroup extends StatelessWidget {
  const _AccountGroup({required this.children});

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

class _AccountInfoTile extends StatelessWidget {
  const _AccountInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

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
      subtitle: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: DarkKickColors.textTertiary,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
      subtitle: Text(
        subtitle,
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

class _DeleteAccountTile extends StatelessWidget {
  const _DeleteAccountTile({required this.onTap});

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
              Icon(Icons.delete_outline, color: Color(0xFFFF4D5D)),
              SizedBox(width: 14),
              Text(
                'Удалить аккаунт',
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
