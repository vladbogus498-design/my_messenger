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
import '../utils/user_formatters.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showBackButton = true, this.chatId});

  final bool showBackButton;
  final String? chatId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _bioController = TextEditingController();
  bool _busy = false;

  String? get _uid => _auth.currentUser?.uid;

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _bioController.dispose();
    super.dispose();
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
      appLogger.e(
        'Profile avatar Firestore update failed: '
        '${error.code} ${error.message ?? ''}',
        error: error,
      );
      _showMessage(
        'Не удалось загрузить аватар: ${_firebaseErrorText(error)}',
      );
    } catch (error) {
      appLogger.e('Avatar upload failed: $error', error: error);
      _showMessage(
        'Не удалось загрузить аватар: ${_friendlyUploadError(error)}',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _saveProfile() async {
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
      return true;
    } on FirebaseException catch (error) {
      appLogger.e(
        'Profile save failed: ${error.code} ${error.message ?? ''}',
        error: error,
      );
      _showMessage(
        'Не удалось сохранить профиль: ${_firebaseErrorText(error)}',
      );
      return false;
    } catch (error) {
      appLogger.e('Profile save failed', error: error);
      _showMessage('Не удалось сохранить профиль: $error');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startEditing(UserModel user) {
    _nameController.text = user.name;
    _tagController.text = user.username ?? user.tag ?? '';
    _bioController.text = user.bio ?? '';
    appLogger.d(
      'Opening profile edit dialog: name="${_nameController.text}" '
      'tag="${_tagController.text}" bioLength=${_bioController.text.length}',
    );
    _showEditProfileDialog();
  }

  Future<void> _showEditProfileDialog() async {
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: DarkKickColors.panel,
              surfaceTintColor: DarkKickColors.neonPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: DarkKickColors.stroke),
              ),
              title: Text(
                'Изменить профиль',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DarkInput(
                      controller: _nameController,
                      hint: 'Имя',
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    _DarkInput(
                      controller: _tagController,
                      hint: 'Tag / username',
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    _DarkInput(
                      controller: _bioController,
                      hint: 'О себе',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setDialogState(() => saving = true);
                          final saved = await _saveProfile();
                          if (saved && context.mounted) {
                            Navigator.pop(context);
                          } else {
                            setDialogState(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _friendlyUploadError(Object error) {
    final text = error.toString();
    if (text.contains('Cloudinary') &&
        (text.contains('not configured') ||
            text.contains('не настроен') ||
            text.contains('signature endpoint'))) {
      return 'Cloudinary не настроен. В Codemagic добавь Environment variables: '
          'CLOUDINARY_CLOUD_NAME и CLOUDINARY_UPLOAD_PRESET, build script '
          'передаст их через --dart-define.';
    }
    return text;
  }

  String _firebaseErrorText(FirebaseException error) {
    final message = error.message?.trim();
    if (message == null || message.isEmpty) return error.code;
    return '${error.code}: $message';
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(showBackButton: true),
      ),
    );
  }

  void _showFutureMessage(String title) {
    _showMessage('$title появится в будущих настройках');
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Scaffold(
      backgroundColor: DarkKickColors.darkBackground,
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
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                    children: [
                      _ProfileTopBar(
                        showBackButton: widget.showBackButton,
                        onBack: () => Navigator.pop(context),
                        onSettings: _openSettings,
                      ),
                      const SizedBox(height: 16),
                      _ProfileHeroCard(
                        user: user,
                        busy: _busy,
                        onAvatarTap: _busy ? null : _uploadAvatar,
                        onEditTap: _busy ? null : () => _startEditing(user),
                      ),
                      const SizedBox(height: 16),
                      _ProfileInfoPanel(user: user),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: 'Настройки',
                        subtitle: 'Разделы уже готовы под развитие профиля',
                      ),
                      const SizedBox(height: 12),
                      _SettingsGrid(
                        items: [
                          _SettingsTileData(
                            icon: Icons.security_outlined,
                            title: 'Безопасность',
                            subtitle: 'Пароль, E2EE, устройства',
                            onTap: _openSettings,
                          ),
                          _SettingsTileData(
                            icon: Icons.shield_outlined,
                            title: 'Приватность',
                            subtitle: 'Кто может писать',
                            onTap: () => _showFutureMessage('Приватность'),
                          ),
                          _SettingsTileData(
                            icon: Icons.palette_outlined,
                            title: 'Внешний вид',
                            subtitle: 'Тема, цвета, иконки',
                            onTap: () => _showFutureMessage('Внешний вид'),
                          ),
                          _SettingsTileData(
                            icon: Icons.devices_outlined,
                            title: 'Устройства',
                            subtitle: 'Активные входы',
                            onTap: () => _showFutureMessage('Устройства'),
                          ),
                          _SettingsTileData(
                            icon: Icons.notifications_none_outlined,
                            title: 'Уведомления',
                            subtitle: 'Звуки и баннеры',
                            onTap: () => _showFutureMessage('Уведомления'),
                          ),
                          _SettingsTileData(
                            icon: Icons.info_outline,
                            title: 'О приложении',
                            subtitle: 'Darkkick MVP',
                            onTap: _openSettings,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.showBackButton,
    required this.onBack,
    required this.onSettings,
  });

  final bool showBackButton;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBackButton)
          _IconCircleButton(icon: Icons.arrow_back_ios_new, onTap: onBack)
        else
          const SizedBox(width: 42),
        Expanded(
          child: Text(
            'Профиль',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _IconCircleButton(icon: Icons.settings_outlined, onTap: onSettings),
      ],
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.user,
    required this.busy,
    required this.onAvatarTap,
    required this.onEditTap,
  });

  final UserModel user;
  final bool busy;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final tag = (user.username ?? user.tag ?? '').trim();
    final bio = (user.bio ?? '').trim();

    return Container(
      height: 316,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: DarkKickColors.stroke),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.18),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/auth_angel.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.54),
                    DarkKickColors.deepBackground.withValues(alpha: 0.98),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ProfileAvatar(
                    user: user,
                    busy: busy,
                    onTap: onAvatarTap,
                    size: 88,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'DARKKICK ID',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tag.isEmpty ? 'tag не указан' : '@$tag',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DarkKickColors.electricPurple,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          bio.isEmpty ? 'О себе не указано' : bio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DarkKickColors.textSecondary,
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _EditProfileButton(onTap: onEditTap),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.user,
    required this.busy,
    required this.onTap,
    required this.size,
  });

  final UserModel user;
  final bool busy;
  final VoidCallback? onTap;
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

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DarkKickColors.neonPurple, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: DarkKickColors.neonPurple.withValues(alpha: 0.38),
                  blurRadius: 24,
                ),
              ],
            ),
            child: ClipOval(
              child: photoUrl == null
                  ? _AvatarFallback(initial: initial)
                  : Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      gaplessPlayback: false,
                      errorBuilder: (_, __, ___) =>
                          _AvatarFallback(initial: initial),
                    ),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: DarkKickColors.neonPurple,
              shape: BoxShape.circle,
              border: Border.all(
                color: DarkKickColors.deepBackground,
                width: 3,
              ),
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(7),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 15,
                  ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DarkKickColors.neonPurple.withValues(alpha: 0.45),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Изменить профиль',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
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

class _ProfileInfoPanel extends StatelessWidget {
  const _ProfileInfoPanel({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final presence = UserFormatters.chatPresence(
      isOnline: user.isOnline,
      lastSeen: user.lastSeen,
    );
    final registration = UserFormatters.registrationDate(user.createdAt);

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      presence,
                      style: TextStyle(
                        color: user.isOnline
                            ? DarkKickColors.online
                            : DarkKickColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DarkKickColors.neonPurple.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DarkKickColors.neonPurple.withValues(alpha: 0.28),
                  ),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: DarkKickColors.electricPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  label: 'Tag',
                  value: (user.username ?? user.tag ?? '').trim().isEmpty
                      ? 'не указан'
                      : '@${(user.username ?? user.tag)!.trim()}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfo(label: 'Регистрация', value: registration),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MiniInfo(
            label: 'О себе',
            value: (user.bio ?? '').trim().isEmpty
                ? 'О себе не указано'
                : user.bio!.trim(),
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.label,
    required this.value,
    this.expanded = false,
  });

  final String label;
  final String value;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DarkKickColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: DarkKickColors.textTertiary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: expanded ? 4 : 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: DarkKickColors.textTertiary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SettingsGrid extends StatelessWidget {
  const _SettingsGrid({required this.items});

  final List<_SettingsTileData> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) => _SettingsTile(data: items[index]),
    );
  }
}

class _SettingsTileData {
  const _SettingsTileData({
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.data});

  final _SettingsTileData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: DarkKickColors.panel.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DarkKickColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconGlow(icon: data.icon),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right,
                      color: DarkKickColors.textTertiary,
                      size: 20,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DarkKickColors.textSecondary,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DarkKickColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DarkKickColors.panel,
            border: Border.all(color: DarkKickColors.stroke),
            boxShadow: [
              BoxShadow(
                color: DarkKickColors.neonPurple.withValues(alpha: 0.18),
                blurRadius: 18,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 19),
        ),
      ),
    );
  }
}

class _IconGlow extends StatelessWidget {
  const _IconGlow({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DarkKickColors.neonPurple.withValues(alpha: 0.14),
        border: Border.all(
          color: DarkKickColors.neonPurple.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.18),
            blurRadius: 18,
          ),
        ],
      ),
      child: Icon(icon, color: DarkKickColors.electricPurple, size: 24),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DarkKickColors.cardSoft,
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DarkInput extends StatelessWidget {
  const _DarkInput({
    required this.controller,
    required this.hint,
    required this.maxLines,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      cursorColor: DarkKickColors.neonPurple,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: DarkKickColors.deepBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DarkKickColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DarkKickColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DarkKickColors.neonPurple),
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
