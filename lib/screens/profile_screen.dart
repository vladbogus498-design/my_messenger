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
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    children: [
                      _SettingsHeader(
                        showBackButton: widget.showBackButton,
                        onBack: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 30),
                      _DarkkickIdCard(
                        user: user,
                        onTap: () => _openEditProfile(user),
                      ),
                      const SizedBox(height: 22),
                      _SettingsList(
                        items: [
                          _SettingsItemData(
                            icon: Icons.person_outline,
                            title: 'Профиль',
                            subtitle: 'Имя, username, аватар',
                            onTap: () => _openEditProfile(user),
                          ),
                          _SettingsItemData(
                            icon: Icons.lock_outline,
                            title: 'Безопасность',
                            subtitle: 'Пароль и устройства',
                            onTap: () => _openPlaceholder('Безопасность'),
                          ),
                          _SettingsItemData(
                            icon: Icons.shield_outlined,
                            title: 'Приватность',
                            subtitle: 'Кто может писать, звонить',
                            onTap: () => _openPlaceholder('Приватность'),
                          ),
                          _SettingsItemData(
                            icon: Icons.chat_bubble_outline,
                            title: 'Чаты',
                            subtitle: 'Темы, размер текста',
                            onTap: () => _openPlaceholder('Чаты'),
                          ),
                          _SettingsItemData(
                            icon: Icons.notifications_none_outlined,
                            title: 'Уведомления',
                            subtitle: 'Звуки, вибрация, баннеры',
                            onTap: () => _openPlaceholder('Уведомления'),
                          ),
                          _SettingsItemData(
                            icon: Icons.palette_outlined,
                            title: 'Внешний вид',
                            subtitle: 'Тема, цвета, иконки',
                            onTap: () => _openPlaceholder('Внешний вид'),
                          ),
                          _SettingsItemData(
                            icon: Icons.devices_outlined,
                            title: 'Активные устройства',
                            subtitle: 'Управление входами',
                            onTap: () =>
                                _openPlaceholder('Активные устройства'),
                          ),
                          _SettingsItemData(
                            icon: Icons.info_outline,
                            title: 'О приложении',
                            subtitle: 'Версия, поддержка',
                            onTap: () => _openPlaceholder('О приложении'),
                          ),
                          _SettingsItemData(
                            icon: Icons.more_horiz,
                            title: 'Дополнительно',
                            subtitle: 'Язык, данные, экспериментальные',
                            onTap: () => _openPlaceholder('Дополнительно'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _LogoutGlassButton(
                        onTap: () async {
                          await UserService.setPresence(
                            isOnline: false,
                            force: true,
                          );
                          await _auth.signOut();
                        },
                      ),
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

  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fillControllers(widget.initialUser);
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

    setState(() => _busy = true);
    try {
      await UserService.updateUserData(
        name: nextName,
        tag: nextTag,
        bio: nextBio,
      );
      appLogger.d('Profile save completed successfully');
      _showMessage('Профиль сохранён');
      if (mounted) Navigator.pop(context);
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
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
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
                const SizedBox(height: 40),
                _ProfileFieldCard(
                  label: 'Имя',
                  controller: _nameController,
                  maxLines: 1,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _ProfileFieldCard(
                  label: 'Username',
                  controller: _tagController,
                  maxLines: 1,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _ProfileFieldCard(
                  label: 'О себе',
                  controller: _bioController,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 134,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: DarkKickColors.panel.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.035)),
            gradient: LinearGradient(
              colors: [
                DarkKickColors.cardSoft.withValues(alpha: 0.82),
                DarkKickColors.panel.withValues(alpha: 0.72),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: DarkKickColors.neonPurple.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            children: [
              _ProfileAvatar(user: user, size: 82),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DARKKICK ID',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tag.isEmpty ? 'tag не указан' : '@$tag',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DarkKickColors.textSecondary,
                        fontSize: 15,
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

class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.items});

  final List<_SettingsItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.035)),
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
                  color: Colors.white.withValues(alpha: 0.055),
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
        child: SizedBox(
          height: 92,
          child: Row(
            children: [
              const SizedBox(width: 22),
              _SettingsIcon(icon: data.icon),
              const SizedBox(width: 20),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DarkKickColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: DarkKickColors.textSecondary,
                size: 26,
              ),
              const SizedBox(width: 18),
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
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DarkKickColors.neonPurple.withValues(alpha: 0.08),
              boxShadow: [
                BoxShadow(
                  color: DarkKickColors.neonPurple.withValues(alpha: 0.22),
                  blurRadius: 18,
                ),
              ],
            ),
          ),
          Icon(icon, color: DarkKickColors.neonPurple, size: 30),
        ],
      ),
    );
  }
}

class _LogoutGlassButton extends StatelessWidget {
  const _LogoutGlassButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF2A080D).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFFF405A).withValues(alpha: 0.34),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.logout, color: Color(0xFFFF4D5D), size: 22),
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
    return Row(
      children: [
        _SmallIconButton(icon: Icons.arrow_back_ios_new, onTap: onBack),
        Expanded(
          child: Text(
            'Профиль',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: onSave,
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DarkKickColors.neonPurple,
                  ),
                )
              : const Text(
                  'Сохранить',
                  style: TextStyle(
                    color: DarkKickColors.electricPurple,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
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
          _ProfileAvatar(user: user, size: 176),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: DarkKickColors.brightPurple,
              shape: BoxShape.circle,
              border: Border.all(
                color: DarkKickColors.deepBackground,
                width: 4,
              ),
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 24,
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
    required this.maxLines,
    required this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: DarkKickColors.textSecondary,
              fontSize: 15,
            ),
          ),
          TextField(
            controller: controller,
            maxLines: maxLines,
            textInputAction: textInputAction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              height: 1.3,
            ),
            cursorColor: DarkKickColors.neonPurple,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.only(top: 10),
            ),
          ),
        ],
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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: DarkKickColors.neonPurple, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.28),
            blurRadius: 24,
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
            child: Icon(icon, color: DarkKickColors.neonPurple, size: 22),
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
