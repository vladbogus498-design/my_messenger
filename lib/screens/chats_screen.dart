import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/chat.dart';
import '../providers/chats_provider.dart';
import '../theme/darkkick_colors.dart';
import '../utils/navigation_animations.dart';
import '../utils/time_formatter.dart';
import '../utils/user_formatters.dart';
import 'new_chat_screen.dart';
import 'settings_screen.dart';
import 'single_chat_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  int _selectedFilterIndex = 0;
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkKickColors.darkBackground,
      body: IndexedStack(
        index: _selectedNavIndex,
        children: [
          _buildChatsHome(),
          const _DarkkickPlaceholder(
            icon: Icons.phone_outlined,
            title: 'Звонки',
            subtitle: 'Голосовые и приватные звонки появятся здесь.',
          ),
          const _DarkkickPlaceholder(
            icon: Icons.people_outline,
            title: 'Люди',
            subtitle: 'Поиск людей и контакты будут в этом разделе.',
          ),
          const SettingsScreen(showBackButton: false),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildChatsHome() {
    final chatsState = ref.watch(chatsProvider);

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          chatsState.when(
            data: (chats) => _buildStoriesList(chats),
            loading: () => _buildStoriesSkeleton(),
            error: (_, __) => const SizedBox(height: 14),
          ),
          _buildFilterTabs(),
          Expanded(
            child: chatsState.when(
              data: _buildChatsList,
              loading: _buildLoadingState,
              error: (error, _) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: DarkKickColors.textPrimary),
            onPressed: () {},
          ),
          Expanded(
            child: Text(
              'DARKKICK',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: DarkKickColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 3.4,
              ),
            ),
          ),
          _IconFrame(
            icon: Icons.edit_square,
            onTap: () => Navigator.push(
              context,
              NavigationAnimations.slideFadeRoute(const NewChatScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: DarkKickColors.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DarkKickColors.divider),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(
              Icons.search,
              color: DarkKickColors.textTertiary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: DarkKickColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Поиск',
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: DarkKickColors.textTertiary,
                  size: 18,
                ),
                onPressed: _searchController.clear,
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(
                  Icons.tune,
                  color: DarkKickColors.neonPurple,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesList(List<Chat> chats) {
    final personalChats = chats.where((chat) => chat.isDirect).take(8).toList();
    final currentUserId = _currentUserId;

    return SizedBox(
      height: 86,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: personalChats.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _StoryItem(
              label: 'Создать',
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DarkKickColors.panel,
                  border: Border.all(color: DarkKickColors.stroke),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 26),
              ),
              onTap: () => Navigator.push(
                context,
                NavigationAnimations.slideFadeRoute(const NewChatScreen()),
              ),
            );
          }

          final chat = personalChats[index - 1];
          return _DirectAwareStoryItem(
            chat: chat,
            currentUserId: currentUserId,
            fallbackTitle: _fallbackTitle(chat),
            onTap: () => _openChat(chat),
          );
        },
      ),
    );
  }

  Widget _buildStoriesSkeleton() {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, __) => Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DarkKickColors.panel,
            border: Border.all(color: DarkKickColors.divider),
          ),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemCount: 5,
      ),
    );
  }

  Widget _buildFilterTabs() {
    const filters = ['Все', 'Личные', 'Группы', 'Каналы'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == filters.length - 1 ? 0 : 7,
              ),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilterIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? DarkKickColors.cardSoft
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: isSelected
                          ? DarkKickColors.stroke
                          : DarkKickColors.divider,
                    ),
                  ),
                  child: Text(
                    filters[index],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : DarkKickColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildChatsList(List<Chat> allChats) {
    final chats = _filterChats(allChats);
    final currentUserId = _currentUserId;

    if (chats.isEmpty) {
      final isChannels = _selectedFilterIndex == 3;
      return _EmptyState(
        title: isChannels ? 'Каналов пока нет' : 'Здесь пока пусто',
        subtitle: isChannels
            ? 'В текущей модели чата нет отдельного типа канала.'
            : 'Создай чат или измени фильтр, чтобы увидеть переписки.',
        icon: isChannels ? Icons.campaign_outlined : Icons.chat_bubble_outline,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      itemCount: chats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return _ChatTile(
          chat: chat,
          currentUserId: currentUserId,
          fallbackTitle: _fallbackTitle(chat),
          onTap: () => _openChat(chat),
        );
      },
    );
  }

  List<Chat> _filterChats(List<Chat> chats) {
    var filtered = chats;
    if (_selectedFilterIndex == 1) {
      filtered = filtered.where((chat) => chat.isDirect).toList();
    } else if (_selectedFilterIndex == 2) {
      filtered = filtered.where((chat) => chat.isGroup).toList();
    } else if (_selectedFilterIndex == 3) {
      filtered = const [];
    }

    if (_searchQuery.isEmpty) return filtered;
    return filtered
        .where(
          (chat) => _fallbackTitle(chat).toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: DarkKickColors.neonPurple),
    );
  }

  Widget _buildErrorState(Object error) {
    return const _EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'Не удалось загрузить чаты',
      subtitle: 'Проверь подключение и попробуй открыть экран ещё раз.',
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: DarkKickColors.darkBackground,
        border: Border(top: BorderSide(color: DarkKickColors.divider)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) => setState(() => _selectedNavIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Чаты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_outlined),
            activeIcon: Icon(Icons.phone),
            label: 'Звонки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Люди',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }

  String _fallbackTitle(Chat chat) => chat.groupName ?? chat.name;

  void _openChat(Chat chat) {
    Navigator.push(
      context,
      NavigationAnimations.slideFadeRoute(
        SingleChatScreen(
          chatId: chat.id,
          chatName: _fallbackTitle(chat),
          otherUserId: chat.otherParticipantId(_currentUserId),
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.chat,
    required this.currentUserId,
    required this.fallbackTitle,
    required this.onTap,
  });

  final Chat chat;
  final String? currentUserId;
  final String fallbackTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final otherUserId = chat.isDirect
        ? chat.otherParticipantId(currentUserId)
        : null;

    return StreamBuilder<_PeerMeta>(
      stream: _peerMetaStream(otherUserId),
      builder: (context, snapshot) {
        final meta = snapshot.data;
        final title = chat.isDirect
            ? meta?.name ?? fallbackTitle
            : fallbackTitle;
        final photoUrl = chat.isDirect ? meta?.photoUrl : null;
        final presence = meta == null || !chat.isDirect
            ? null
            : UserFormatters.compactPresence(
                isOnline: meta.isOnline,
                lastSeen: meta.lastSeen,
              );
        final unread = chat.unreadFor(currentUserId);
        final shouldShowStatus =
            unread == 0 &&
            currentUserId != null &&
            chat.lastSenderId == currentUserId;
        final isReadByOther =
            currentUserId != null &&
            chat.lastMessageReadBy.any((uid) => uid != currentUserId);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DarkKickColors.panel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: DarkKickColors.divider),
              ),
              child: Row(
                children: [
                  _ChatAvatar(
                    title: title,
                    photoUrl: photoUrl,
                    isGroup: chat.isGroup,
                    size: 52,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (chat.isGroup)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.group,
                                  color: DarkKickColors.neonPurple,
                                  size: 14,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (presence != null) ...[
                          Text(
                            presence,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: meta!.isOnline
                                  ? DarkKickColors.online
                                  : DarkKickColors.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DarkKickColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        TimeFormatter.formatChatTime(chat.lastMessageTime),
                        style: const TextStyle(
                          color: DarkKickColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (unread > 0)
                        _UnreadBadge(count: unread)
                      else if (shouldShowStatus)
                        Icon(
                          isReadByOther ? Icons.done_all : Icons.done,
                          size: 16,
                          color: isReadByOther
                              ? DarkKickColors.neonPurple
                              : DarkKickColors.textTertiary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DirectAwareStoryItem extends StatelessWidget {
  const _DirectAwareStoryItem({
    required this.chat,
    required this.currentUserId,
    required this.fallbackTitle,
    required this.onTap,
  });

  final Chat chat;
  final String? currentUserId;
  final String fallbackTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final otherUserId = chat.otherParticipantId(currentUserId);

    return StreamBuilder<_PeerMeta>(
      stream: _peerMetaStream(otherUserId),
      builder: (context, snapshot) {
        final meta = snapshot.data;
        final title = meta?.name ?? fallbackTitle;
        return _StoryItem(
          label: title,
          onTap: onTap,
          child: _ChatAvatar(
            title: title,
            photoUrl: meta?.photoUrl,
            isGroup: chat.isGroup,
            size: 58,
          ),
        );
      },
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DarkKickColors.neonPurple,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.35),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.title,
    required this.photoUrl,
    required this.isGroup,
    required this.size,
  });

  final String title;
  final String? photoUrl;
  final bool isGroup;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = title.trim().isEmpty ? '?' : title.trim()[0].toUpperCase();
    final color = _avatarColor(title);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: DarkKickColors.stroke),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.22),
            blurRadius: 14,
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AvatarFallback(
                  color: color,
                  initial: initial,
                  isGroup: isGroup,
                  size: size,
                ),
              )
            : _AvatarFallback(
                color: color,
                initial: initial,
                isGroup: isGroup,
                size: size,
              ),
      ),
    );
  }

  Color _avatarColor(String value) {
    final hash = value.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    const colors = [
      Color(0xFF2E0C61),
      Color(0xFF40116E),
      Color(0xFF1A237E),
      Color(0xFF311B92),
      Color(0xFF4A148C),
    ];
    return colors[hash % colors.length];
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.color,
    required this.initial,
    required this.isGroup,
    required this.size,
  });

  final Color color;
  final String initial;
  final bool isGroup;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(
        child: isGroup
            ? const Icon(Icons.groups_2_outlined, color: Colors.white)
            : Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _PeerMeta {
  const _PeerMeta({
    required this.name,
    this.photoUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  final String name;
  final String? photoUrl;
  final bool isOnline;
  final DateTime? lastSeen;
}

Stream<_PeerMeta>? _peerMetaStream(String? uid) {
  if (uid == null || uid.isEmpty) return null;

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) {
        final data = doc.data() ?? const <String, dynamic>{};
        final email = (data['email'] ?? '').toString();
        final fallback = email.contains('@')
            ? email.split('@').first
            : 'Пользователь';
        final name = (data['name'] ?? fallback).toString();
        final photoUrl = UserFormatters.readPhotoUrl(data);
        final avatarUpdatedAt = UserFormatters.readDate(
          data['avatarUpdatedAt'],
        );
        final lastSeen = data['lastSeen'] is Timestamp
            ? (data['lastSeen'] as Timestamp).toDate()
            : null;
        return _PeerMeta(
          name: name,
          photoUrl: UserFormatters.versionedImageUrl(photoUrl, avatarUpdatedAt),
          isOnline: data['isOnline'] == true,
          lastSeen: lastSeen,
        );
      });
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({
    required this.child,
    required this.label,
    required this.onTap,
  });

  final Widget child;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 62,
        child: Column(
          children: [
            child,
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DarkKickColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconFrame extends StatelessWidget {
  const _IconFrame({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: DarkKickColors.panel,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: DarkKickColors.stroke),
          boxShadow: [
            BoxShadow(
              color: DarkKickColors.neonPurple.withValues(alpha: 0.18),
              blurRadius: 16,
            ),
          ],
        ),
        child: Icon(icon, color: DarkKickColors.neonPurple, size: 20),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: DarkKickColors.neonPurple, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DarkKickColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkkickPlaceholder extends StatelessWidget {
  const _DarkkickPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DarkKickColors.panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: DarkKickColors.divider),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: DarkKickColors.neonPurple, size: 42),
                    const SizedBox(height: 14),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: DarkKickColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
