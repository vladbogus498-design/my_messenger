import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../theme/darkkick_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  UserModel? _user;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final current = _auth.currentUser;
    if (current == null) {
      setState(() => _isLoading = false);
      return;
    }

    final user = await UserService.getUserData(current.uid);
    if (!mounted) return;
    setState(() {
      _user = user ??
          UserModel(
            uid: current.uid,
            email: current.email ?? '',
            name: current.displayName ?? current.email?.split('@').first ?? 'Пользователь',
            photoURL: current.photoURL,
          );
      _nameController.text = _user!.name;
      _bioController.text = _user!.bio ?? '';
      _isLoading = false;
    });
  }

  Future<void> _uploadAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    try {
      _showMessage('Загружаем аватар...');
      final url = await StorageService.uploadUserAvatar(File(picked.path));
      await UserService.updateUserData(photoURL: url);
      await _loadUser();
      _showMessage('Аватар обновлен');
    } catch (error) {
      _showMessage('Не удалось загрузить аватар: $error');
    }
  }

  Future<void> _saveProfile() async {
    try {
      await UserService.updateUserData(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
      );
      setState(() => _isEditing = false);
      await _loadUser();
      _showMessage('Профиль сохранен');
    } catch (error) {
      _showMessage('Не удалось сохранить профиль: $error');
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkKickColors.darkBackground,
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text('Обо мне'),
        actions: [
          if (_user != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit_outlined),
              onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: DarkKickColors.neonPurple))
          : _user == null
              ? const _ProfileEmptyState()
              : SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(),
                        const SizedBox(height: 18),
                        _buildBioCard(),
                        const SizedBox(height: 14),
                        _buildStatsGrid(),
                        const SizedBox(height: 14),
                        _ActionCard(
                          icon: Icons.favorite_border,
                          title: 'Поддержать разработчика',
                          subtitle: 'Если тебе нравится Darkkick, спасибо за поддержку.',
                          trailing: Icons.favorite_border,
                          onTap: () => _showMessage('Раздел поддержки скоро появится'),
                        ),
                        const SizedBox(height: 12),
                        _ActionCard(
                          icon: Icons.person_add_alt_1_outlined,
                          title: 'Пригласить друзей',
                          subtitle: 'Расскажи о Darkkick',
                          trailing: Icons.arrow_forward_ios,
                          onTap: () => _showMessage('Приглашения скоро появятся'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHero() {
    final user = _user!;
    final accountAge = _accountAgeText(user.createdAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DarkKickColors.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DarkKickColors.divider),
        image: DecorationImage(
          image: const AssetImage('assets/images/auth_angel.png'),
          fit: BoxFit.cover,
          opacity: 0.16,
          alignment: Alignment.centerRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isEditing
                    ? TextField(
                        controller: _nameController,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                        decoration: const InputDecoration(hintText: 'Имя'),
                      )
                    : Text(
                        user.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                const SizedBox(height: 8),
                Text(
                  user.email.isEmpty ? 'Email не указан' : user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: DarkKickColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$accountAge\n'),
                      const TextSpan(text: 'Одно '),
                      TextSpan(
                        text: 'приложение.',
                        style: const TextStyle(color: DarkKickColors.electricPurple),
                      ),
                    ],
                  ),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _uploadAvatar,
            child: _ProfileAvatar(user: user),
          ),
        ],
      ),
    );
  }

  Widget _buildBioCard() {
    final bio = _user!.bio?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DarkKickColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DarkKickColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'О себе',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          if (_isEditing)
            TextField(
              controller: _bioController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Расскажи о себе...'),
            )
          else
            Text(
              bio == null || bio.isEmpty
                  ? 'Расскажи о себе: кто ты, чем занимаешься и зачем тебе Darkkick.'
                  : bio,
              style: const TextStyle(
                color: DarkKickColors.textSecondary,
                height: 1.45,
              ),
            ),
          const SizedBox(height: 14),
          Text(
            '- ${_user!.name}',
            style: GoogleFonts.caveat(
              color: DarkKickColors.textSecondary,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    const stats = [
      _ProfileStat(icon: Icons.code, value: '50 000+', label: 'строк кода'),
      _ProfileStat(icon: Icons.schedule, value: '60 дней', label: 'без остановки'),
      _ProfileStat(icon: Icons.bolt, value: '100%', label: 'в соло'),
    ];

    return Row(
      children: stats
          .map(
            (stat) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: stat,
              ),
            ),
          )
          .toList(),
    );
  }

  String _accountAgeText(DateTime? createdAt) {
    if (createdAt == null) return 'Новый профиль.';
    final days = DateTime.now().difference(createdAt).inDays;
    if (days < 1) return 'Сегодня.';
    if (days < 31) return '$days дн.';
    final months = (days / 30).floor();
    return '$months мес.';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final initial = user.name.isEmpty ? '?' : user.name[0].toUpperCase();
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: DarkKickColors.stroke),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.36),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipOval(
        child: user.photoURL != null && user.photoURL!.isNotEmpty
            ? Image.network(user.photoURL!, fit: BoxFit.cover)
            : ColoredBox(
                color: DarkKickColors.cardSoft,
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DarkKickColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DarkKickColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: DarkKickColors.neonPurple, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: DarkKickColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IconData trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DarkKickColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DarkKickColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, color: DarkKickColors.neonPurple, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: DarkKickColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(trailing, color: DarkKickColors.neonPurple, size: 18),
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
