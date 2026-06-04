import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../theme/darkkick_colors.dart';
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
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isEditing = false;
  bool _busy = false;

  String? get _uid => _auth.currentUser?.uid;

  @override
  void dispose() {
    _nameController.dispose();
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
      final url = await StorageService.uploadUserAvatar(File(picked.path));
      await UserService.updateUserData(photoURL: url);
      _showMessage('Аватар обновлён');
    } catch (error) {
      _showMessage('Не удалось загрузить аватар: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _busy = true);
    try {
      await UserService.updateUserData(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
      );
      if (mounted) setState(() => _isEditing = false);
      _showMessage('Профиль сохранён');
    } catch (error) {
      _showMessage('Не удалось сохранить профиль: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startEditing(UserModel user) {
    _nameController.text = user.name;
    _bioController.text = user.bio ?? '';
    setState(() => _isEditing = true);
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
      appBar: AppBar(
        backgroundColor: DarkKickColors.darkBackground,
        elevation: 0,
        centerTitle: true,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Профиль',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _busy ? null : _saveProfile,
              child: const Text('Готово'),
            ),
        ],
      ),
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
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                    children: [
                      Center(
                        child: _ProfileAvatar(
                          user: user,
                          busy: _busy,
                          onTap: _busy ? null : _uploadAvatar,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_isEditing) ...[
                        _DarkInput(
                          controller: _nameController,
                          hint: 'Имя',
                          maxLines: 1,
                        ),
                        const SizedBox(height: 12),
                        _DarkInput(
                          controller: _bioController,
                          hint: 'О себе',
                          maxLines: 3,
                        ),
                      ] else ...[
                        Center(
                          child: Text(
                            user.name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            UserFormatters.chatPresence(
                              isOnline: user.isOnline,
                              lastSeen: user.lastSeen,
                            ),
                            style: TextStyle(
                              color: user.isOnline
                                  ? DarkKickColors.online
                                  : DarkKickColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            user.email.isEmpty ? '@darkkick' : user.email,
                            style: const TextStyle(
                              color: DarkKickColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Text(
                            (user.bio ?? '').trim().isEmpty
                                ? 'О себе не указано'
                                : user.bio!.trim(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: DarkKickColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: Text(
                            'Дата регистрации\n${UserFormatters.registrationDate(user.createdAt)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: DarkKickColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _ActionCard(
                        icon: Icons.edit_outlined,
                        title: 'Изменить профиль',
                        onTap: () =>
                            _isEditing ? _saveProfile() : _startEditing(user),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.photo_camera_outlined,
                        title: 'Изменить аватарку',
                        onTap: _busy ? () {} : _uploadAvatar,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.user,
    required this.busy,
    required this.onTap,
  });

  final UserModel user;
  final bool busy;
  final VoidCallback? onTap;

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
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DarkKickColors.stroke, width: 2),
              boxShadow: [
                BoxShadow(
                  color: DarkKickColors.neonPurple.withValues(alpha: 0.34),
                  blurRadius: 28,
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DarkKickColors.neonPurple,
              shape: BoxShape.circle,
              border: Border.all(
                color: DarkKickColors.darkBackground,
                width: 3,
              ),
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 17,
                  ),
          ),
        ],
      ),
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
            fontSize: 42,
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
        fillColor: DarkKickColors.panel,
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: DarkKickColors.panel,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: DarkKickColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, color: DarkKickColors.neonPurple, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: DarkKickColors.textTertiary,
              ),
            ],
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
