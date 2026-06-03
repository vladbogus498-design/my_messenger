import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../theme/darkkick_colors.dart';
import '../utils/navigation_animations.dart';
import '../utils/user_formatters.dart';
import 'single_chat_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({
    super.key,
    this.userId,
    this.isMyProfile = false,
    this.chatId,
  });

  final String? userId;
  final bool isMyProfile;
  final String? chatId;

  String get _targetUserId =>
      userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final targetUserId = _targetUserId;

    return Scaffold(
      backgroundColor: DarkKickColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DarkKickColors.darkBackground,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Профиль',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: targetUserId.isEmpty
          ? const _UserEmptyState()
          : StreamBuilder<UserModel?>(
              stream: UserService.watchUserData(targetUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: DarkKickColors.neonPurple,
                    ),
                  );
                }

                final user = snapshot.data;
                if (user == null) return const _UserEmptyState();

                return DefaultTabController(
                  length: 2,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                            children: [
                              _ProfileHeader(user: user),
                              const SizedBox(height: 18),
                              _ProfileActions(
                                user: user,
                                chatId: chatId,
                                isMyProfile:
                                    isMyProfile ||
                                    FirebaseAuth.instance.currentUser?.uid ==
                                        user.uid,
                              ),
                              const SizedBox(height: 18),
                              _InfoCard(user: user),
                              const SizedBox(height: 20),
                              const TabBar(
                                labelColor: Colors.white,
                                unselectedLabelColor:
                                    DarkKickColors.textTertiary,
                                indicatorColor: DarkKickColors.neonPurple,
                                tabs: [
                                  Tab(text: 'Фото'),
                                  Tab(text: 'Инфо'),
                                ],
                              ),
                              SizedBox(
                                height: 250,
                                child: TabBarView(
                                  children: [
                                    _PhotoGrid(chatId: chatId),
                                    const _AboutTab(),
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
              },
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final status = UserFormatters.chatPresence(
      isOnline: user.isOnline,
      lastSeen: user.lastSeen,
    );

    return Column(
      children: [
        _LargeAvatar(user: user),
        const SizedBox(height: 16),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          status,
          style: TextStyle(
            color: user.isOnline
                ? DarkKickColors.online
                : DarkKickColors.textTertiary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '@${user.username ?? user.tag ?? user.email.split('@').first}',
          style: const TextStyle(
            color: DarkKickColors.textTertiary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          (user.bio ?? '').trim().isEmpty
              ? 'Пользователь Darkkick. Без лишнего шума.'
              : user.bio!.trim(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: DarkKickColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _LargeAvatar extends StatelessWidget {
  const _LargeAvatar({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final initial = user.name.trim().isEmpty
        ? '?'
        : user.name.trim()[0].toUpperCase();

    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: DarkKickColors.stroke, width: 2),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.32),
            blurRadius: 28,
          ),
        ],
      ),
      child: ClipOval(
        child: user.photoURL != null && user.photoURL!.isNotEmpty
            ? Image.network(
                user.photoURL!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AvatarFallback(initial: initial),
              )
            : _AvatarFallback(initial: initial),
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

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({
    required this.user,
    required this.chatId,
    required this.isMyProfile,
  });

  final UserModel user;
  final String? chatId;
  final bool isMyProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: isMyProfile ? 'Это вы' : 'Написать',
            onTap: isMyProfile ? null : () => _openChat(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.phone_outlined,
            label: 'Позвонить',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Звонки появятся позже')),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openChat(BuildContext context) async {
    final navigator = Navigator.of(context);
    final id =
        chatId ??
        await ChatService.createChat(
          otherUserId: user.uid,
          chatName: user.name,
        );
    navigator.pushReplacement(
      NavigationAnimations.slideFadeRoute(
        SingleChatScreen(
          chatId: id,
          chatName: user.name,
          otherUserId: user.uid,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: DarkKickColors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DarkKickColors.divider),
          ),
          child: Column(
            children: [
              Icon(icon, color: DarkKickColors.neonPurple),
              const SizedBox(height: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarkKickColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DarkKickColors.divider),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email.isEmpty ? 'Скрыт' : user.email,
          ),
          const Divider(color: DarkKickColors.divider),
          _InfoRow(
            icon: Icons.calendar_month_outlined,
            label: 'Дата регистрации',
            value: UserFormatters.registrationDate(user.createdAt),
          ),
          const Divider(color: DarkKickColors.divider),
          _InfoRow(
            icon: Icons.circle,
            label: 'Статус',
            value: UserFormatters.chatPresence(
              isOnline: user.isOnline,
              lastSeen: user.lastSeen,
            ),
            iconColor: user.isOnline
                ? DarkKickColors.online
                : DarkKickColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? DarkKickColors.neonPurple, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: DarkKickColors.textTertiary),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.chatId});

  final String? chatId;

  @override
  Widget build(BuildContext context) {
    final id = chatId;
    if (id == null || id.isEmpty) {
      return const _ProfileTabEmpty(
        text: 'Фотографии появятся после переписки',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(id)
          .collection('messages')
          .where('type', isEqualTo: 'image')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final urls = docs
            .map((doc) => doc.data()['imageUrl']?.toString() ?? '')
            .where((url) => url.isNotEmpty)
            .toList();

        if (snapshot.connectionState == ConnectionState.waiting &&
            urls.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: DarkKickColors.neonPurple),
          );
        }
        if (urls.isEmpty) {
          return const _ProfileTabEmpty(text: 'В этом диалоге пока нет фото');
        }

        return GridView.builder(
          padding: const EdgeInsets.only(top: 16),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: urls.length,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(urls[index], fit: BoxFit.cover),
            );
          },
        );
      },
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    return const _ProfileTabEmpty(
      text: 'Здесь будут общие медиа и быстрые действия личного чата',
    );
  }
}

class _ProfileTabEmpty extends StatelessWidget {
  const _ProfileTabEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: DarkKickColors.textSecondary),
      ),
    );
  }
}

class _UserEmptyState extends StatelessWidget {
  const _UserEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Пользователь не найден',
        style: TextStyle(color: DarkKickColors.textSecondary),
      ),
    );
  }
}
