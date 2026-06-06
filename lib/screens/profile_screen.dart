import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../theme/darkkick_colors.dart';
import '../utils/logger.dart';
import '../utils/navigation_animations.dart';
import '../utils/user_formatters.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showBackButton = true, this.chatId});

  final bool showBackButton;
  final String? chatId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  void _openEditProfile(UserModel user) {
    Navigator.push(
      context,
      NavigationAnimations.slideFadeRoute(
        _EditProfileScreen(initialUser: user),
      ),
    );
  }

  void _openPlaceholder(String title) {
    Navigator.push(
      context,
      NavigationAnimations.slideFadeRoute(
        _ProfilePlaceholderScreen(title: title),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (context) => const _LogoutConfirmDialog(),
    );
    if (shouldLogout != true) return;

    await UserService.setPresence(isOnline: false, force: true);
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Scaffold(
      backgroundColor: DarkKickColors.deepBackground,
      body: uid == null
          ? const _ProfileEmptyState()
          : StreamBuilder<UserModel?>(
              stream: UserService.watchUserData(uid),
              builder: (context, snapshot) {
                final firebaseUser = _auth.currentUser;
                final user =
                    snapshot.data ??
                    UserModel(
                      uid: uid,
                      email: firebaseUser?.email ?? '',
                      name:
                          firebaseUser?.displayName ??
                          firebaseUser?.email?.split('@').first ??
                          'Пользователь',
                      photoURL: firebaseUser?.photoURL,
                    );

                return SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
                    children: [
                      _SettingsHeader(
                        showBackButton: widget.showBackButton,
                        onBack: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 20),
                      _DarkkickIdCard(
                        user: user,
                        onTap: () => _openEditProfile(user),
                      ),
                      const SizedBox(height: 24),
                      _SettingsSection(
                        title: 'АККАУНТ',
                        items: [
                          _SettingsItemData(
                            icon: Icons.person_rounded,
                            title: 'Профиль',
                            subtitle: 'Имя, username, аватар',
                            onTap: () => _openEditProfile(user),
                          ),
                          _SettingsItemData(
                            icon: Icons.shield_rounded,
                            title: 'Приватность',
                            subtitle: 'Кто может писать, онлайн',
                            onTap: () => _openPlaceholder('Приватность'),
                          ),
                          _SettingsItemData(
                            icon: Icons.lock_rounded,
                            title: 'Безопасность',
                            subtitle: 'Пароль, устройства',
                            onTap: () => _openPlaceholder('Безопасность'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SettingsSection(
                        title: 'ОБЩЕНИЕ',
                        items: [
                          _SettingsItemData(
                            icon: Icons.chat_bubble_rounded,
                            title: 'Чаты',
                            subtitle: 'Темы, размер текста',
                            onTap: () => _openPlaceholder('Чаты'),
                          ),
                          _SettingsItemData(
                            icon: Icons.notifications_rounded,
                            title: 'Уведомления',
                            subtitle: 'Звуки, вибрация, баннеры',
                            onTap: () => _openPlaceholder('Уведомления'),
                          ),
                          _SettingsItemData(
                            icon: Icons.devices_rounded,
                            title: 'Активные устройства',
                            subtitle: 'Управление входами',
                            onTap: () =>
                                _openPlaceholder('Активные устройства'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SettingsSection(
                        title: 'ПРИЛОЖЕНИЕ',
                        items: [
                          _SettingsItemData(
                            icon: Icons.palette_rounded,
                            title: 'Внешний вид',
                            subtitle: 'Тема, цвета, иконки',
                            onTap: () => _openPlaceholder('Внешний вид'),
                          ),
                          _SettingsItemData(
                            icon: Icons.info_rounded,
                            title: 'О приложении',
                            subtitle: 'Версия, поддержка',
                            onTap: () => _openPlaceholder('О приложении'),
                          ),
                          _SettingsItemData(
                            icon: Icons.more_horiz_rounded,
                            title: 'Дополнительно',
                            subtitle: 'Язык, данные, экспериментальные',
                            onTap: () => _openPlaceholder('Дополнительно'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _LogoutGlassButton(onTap: _confirmLogout),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen({required this.initialUser});

  final UserModel initialUser;

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _bioController = TextEditingController();
  bool _busy = false;
  bool _usernameTaken = false;

  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fillControllers(widget.initialUser);
    _tagController.addListener(() {
      if (!_usernameTaken || !mounted) return;
      setState(() => _usernameTaken = false);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _fillControllers(UserModel user) {
    _nameController.text = user.name;
    _tagController.text = user.username ?? user.tag ?? '';
    _bioController.text = user.bio ?? '';
  }

  Future<void> _uploadAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      appLogger.d('Avatar upload started: path=${picked.path}');
      final url = await StorageService.uploadUserAvatar(File(picked.path));
      appLogger.d('Avatar upload success: imageUrl=$url');
      appLogger.d('Profile avatar Firestore update started');
      await UserService.updateUserData(photoURL: url);
      appLogger.d('Profile avatar Firestore update finished');
      _showMessage('Аватар обновлён');
    } on FirebaseException catch (error) {
      appLogger.e(
        'Avatar upload failed during Firestore save: '
        '${error.code} ${error.message ?? ''}',
        error: error,
      );
      _showMessage('Не удалось загрузить аватар: ${_firebaseErrorText(error)}');
    } catch (error) {
      appLogger.e('Avatar upload failed: $error', error: error);
      _showMessage(
        'Не удалось загрузить аватар: ${_friendlyUploadError(error)}',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveProfile() async {
    final nextName = _nameController.text.trim();
    final nextTag = _tagController.text.trim();
    final nextBio = _bioController.text.trim();
    appLogger.d(
      'Profile save started: name="$nextName" tag="$nextTag" '
      'bioLength=${nextBio.length}',
    );

    setState(() {
      _busy = true;
      _usernameTaken = false;
    });
    try {
      await UserService.updateUserData(
        name: nextName,
        tag: nextTag,
        bio: nextBio,
      );
      appLogger.d('Profile save completed successfully');
      _showMessage('Профиль сохранён');
      if (mounted) Navigator.pop(context);
    } on UsernameTakenException {
      appLogger.w('Profile save blocked: username already taken');
      if (mounted) {
        setState(() => _usernameTaken = true);
        _showMessage('Username уже занят');
      }
    } on FirebaseException catch (error) {
      appLogger.e(
        'Profile save failed: ${error.code} ${error.message ?? ''}',
        error: error,
      );
      _showMessage(
        'Не удалось сохранить профиль: ${_firebaseErrorText(error)}',
      );
    } catch (error) {
      appLogger.e('Profile save failed', error: error);
      _showMessage('Не удалось сохранить профиль: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyUploadError(Object error) {
    final text = error.toString();
    if (text.contains('Cloudinary') &&
        (text.contains('not configured') ||
            text.contains('не настроен') ||
            text.contains('signature endpoint'))) {
      return 'Cloudinary не настроен. В Codemagic добавь Environment variables: '
          'CLOUDINARY_CLOUD_NAME и CLOUDINARY_UPLOAD_PRESET.';
    }
    return text;
  }

  String _firebaseErrorText(FirebaseException error) {
    final message = error.message?.trim();
    if (message == null || message.isEmpty) return error.code;
    return '${error.code}: $message';
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) return const _ProfileEmptyState();

    return Scaffold(
      backgroundColor: DarkKickColors.deepBackground,
      body: StreamBuilder<UserModel?>(
        stream: UserService.watchUserData(uid),
        builder: (context, snapshot) {
          final user = snapshot.data ?? widget.initialUser;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 34),
              children: [
                _EditHeader(
                  busy: _busy,
                  onBack: () => Navigator.pop(context),
                  onSave: _busy ? null : _saveProfile,
                ),
                const SizedBox(height: 34),
                Center(
                  child: _EditableAvatar(
                    user: user,
                    busy: _busy,
                    onTap: _busy ? null : _uploadAvatar,
                  ),
                ),
                const SizedBox(height: 36),
                _ProfileFieldCard(
                  label: 'Имя',
                  controller: _nameController,
                  height: 76,
                  maxLines: 1,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _ProfileFieldCard(
                  label: 'Username',
                  controller: _tagController,
                  height: 76,
                  maxLines: 1,
                  textInputAction: TextInputAction.next,
                  hasError: _usernameTaken,
                ),
                const SizedBox(height: 14),
                _ProfileFieldCard(
                  label: 'О себе',
                  controller: _bioController,
                  height: 108,
                  minLines: 2,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.showBackButton, required this.onBack});

  final bool showBackButton;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBackButton)
          _SmallIconButton(icon: Icons.arrow_back_ios_new, onTap: onBack),
        if (showBackButton) const SizedBox(width: 12),
        Text(
          'Настройки',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DarkkickIdCard extends StatelessWidget {
  const _DarkkickIdCard({required this.user, required this.onTap});

  final UserModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tag = (user.username ?? user.tag ?? '').trim();
    final displayName = user.name.trim().isEmpty ? 'DARKKICK ID' : user.name;
    final bio = (user.bio ?? '').trim().isEmpty
        ? 'Без границ. Без слежки.\nЭто Darkkick.'
        : user.bio!.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          height: 124,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0814).withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0B0814).withValues(alpha: 0.96),
                const Color(0xFF10091D).withValues(alpha: 0.92),
                const Color(0xFF140B25).withValues(alpha: 0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: DarkKickColors.neonPurple.withValues(alpha: 0.08),
                blurRadius: 28,
                spreadRadius: -8,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: [
              _ProfileAvatar(user: user, size: 80),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tag.isEmpty ? '@darkkick' : '@$tag',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: DarkKickColors.electricPurple.withValues(
                          alpha: 0.95,
                        ),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DarkKickColors.textSecondary,
                        fontSize: 13,
                        height: 1.22,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: DarkKickColors.textSecondary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});

  final String title;
  final List<_SettingsItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              color: DarkKickColors.textTertiary.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        _SettingsList(items: items),
      ],
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.items});

  final List<_SettingsItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0B18).withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF151020).withValues(alpha: 0.72),
            const Color(0xFF0A0711).withValues(alpha: 0.62),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.055),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _SettingsRow(data: items[index]),
            if (index != items.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 86),
                child: Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsItemData {
  const _SettingsItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.data});

  final _SettingsItemData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              const SizedBox(width: 20),
              _SettingsIcon(icon: data.icon),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DarkKickColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: DarkKickColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: DarkKickColors.neonPurple.withValues(alpha: 0.18),
              border: Border.all(
                color: DarkKickColors.neonPurple.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: DarkKickColors.neonPurple.withValues(alpha: 0.1),
                  blurRadius: 14,
                  spreadRadius: -4,
                ),
              ],
            ),
          ),
          Icon(icon, color: DarkKickColors.electricPurple, size: 22),
        ],
      ),
    );
  }
}

class _LogoutGlassButton extends StatelessWidget {
  const _LogoutGlassButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF2A080D).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFFF405A).withValues(alpha: 0.34),
              width: 0.8,
            ),
          ),
          child: const Row(
            children: [
              _LogoutIcon(),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Выйти из аккаунта',
                  style: TextStyle(
                    color: Color(0xFFFF5B6C),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Color(0xFFFF7A88), size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutIcon extends StatelessWidget {
  const _LogoutIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0xFFFF3B5F).withValues(alpha: 0.13),
        border: Border.all(
          color: const Color(0xFFFF3B5F).withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3B5F).withValues(alpha: 0.08),
            blurRadius: 14,
            spreadRadius: -4,
          ),
        ],
      ),
      child: const Icon(
        Icons.logout_rounded,
        color: Color(0xFFFF4D5D),
        size: 22,
      ),
    );
  }
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF11101D).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: DarkKickColors.neonPurple.withValues(alpha: 0.18),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFFFF3358).withValues(alpha: 0.08),
                border: Border.all(
                  color: const Color(0xFFFF3358).withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFFF4D6A),
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Выйти из аккаунта?',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Вы уверены, что хотите выйти?\nДля входа потребуется пароль.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DarkKickColors.textSecondary,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            _LogoutDialogButton(
              label: 'Выйти',
              isDanger: true,
              onTap: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 12),
            _LogoutDialogButton(
              label: 'Отмена',
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutDialogButton extends StatelessWidget {
  const _LogoutDialogButton({
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isDanger
              ? const LinearGradient(
                  colors: [Color(0xFFFF3358), Color(0xFFC91638)],
                )
              : null,
          color: isDanger ? null : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: isDanger
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.05),
            width: 0.8,
          ),
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _EditHeader extends StatelessWidget {
  const _EditHeader({
    required this.busy,
    required this.onBack,
    required this.onSave,
  });

  final bool busy;
  final VoidCallback onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          _SmallIconButton(icon: Icons.arrow_back_ios_new, onTap: onBack),
          Expanded(
            child: Text(
              'Профиль',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onSave,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC084FC),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFC084FC),
                    ),
                  )
                : const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.user,
    required this.busy,
    required this.onTap,
  });

  final UserModel user;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          _ProfileAvatar(user: user, size: 128),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DarkKickColors.deepBackground,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: DarkKickColors.electricPurple.withValues(alpha: 0.24),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileFieldCard extends StatelessWidget {
  const _ProfileFieldCard({
    required this.label,
    required this.controller,
    required this.height,
    required this.maxLines,
    required this.textInputAction,
    this.minLines,
    this.hasError = false,
  });

  final String label;
  final TextEditingController controller;
  final double height;
  final int maxLines;
  final int? minLines;
  final TextInputAction textInputAction;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF100A18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasError
              ? const Color(0xFFFF4D6A).withValues(alpha: 0.72)
              : Colors.white.withValues(alpha: 0.07),
          width: 1,
        ),
        boxShadow: hasError
            ? [
                BoxShadow(
                  color: const Color(0xFFFF4D6A).withValues(alpha: 0.14),
                  blurRadius: 18,
                  spreadRadius: -6,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 16 / 12,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            textInputAction: textInputAction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 22 / 16,
            ),
            textAlignVertical: TextAlignVertical.top,
            cursorColor: DarkKickColors.neonPurple,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _ProfilePlaceholderScreen extends StatelessWidget {
  const _ProfilePlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkKickColors.deepBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SmallIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 34,
                  ),
                  decoration: BoxDecoration(
                    color: DarkKickColors.panel.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  child: const Text(
                    'Раздел в разработке',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DarkKickColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user, required this.size});

  final UserModel user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = user.name.trim().isEmpty
        ? '?'
        : user.name.trim()[0].toUpperCase();
    final photoUrl = UserFormatters.versionedImageUrl(
      user.photoURL,
      user.avatarUpdatedAt,
    );
    final isLarge = size >= 120;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFA855F7).withValues(
            alpha: isLarge ? 0.45 : 0.62,
          ),
          width: isLarge ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(
              alpha: isLarge ? 0.20 : 0.18,
            ),
            blurRadius: isLarge ? 24 : 18,
            spreadRadius: isLarge ? -4 : 0,
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl == null
            ? _AvatarFallback(initial: initial, size: size)
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                gaplessPlayback: false,
                errorBuilder: (_, __, ___) =>
                    _AvatarFallback(initial: initial, size: size),
              ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial, required this.size});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DarkKickColors.cardSoft,
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: size * 0.34,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: Icon(icon, color: DarkKickColors.neonPurple, size: 24),
          ),
        ),
      ),
    );
  }
}

class _ProfileEmptyState extends StatelessWidget {
  const _ProfileEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Войдите в аккаунт, чтобы увидеть профиль',
        style: TextStyle(color: DarkKickColors.textSecondary),
      ),
    );
  }
}
