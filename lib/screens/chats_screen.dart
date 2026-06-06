import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/system_bot.dart';
import '../models/chat.dart';
import '../providers/chats_provider.dart';
import '../theme/darkkick_colors.dart';
import '../utils/navigation_animations.dart';
import '../utils/time_formatter.dart';
import '../utils/user_formatters.dart';
import 'new_chat_screen.dart';
import 'profile_screen.dart';
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: DarkKickColors.darkBackground,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: DarkKickColors.darkBackground,
        systemNavigationBarDividerColor: DarkKickColors.darkBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: DarkKickColors.darkBackground,
        body: ColoredBox(
          color: DarkKickColors.darkBackground,
          child: IndexedStack(
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
              const ProfileScreen(showBackButton: false),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildChatsHome() {
    final chatsState = ref.watch(chatsProvider);

    return ColoredBox(
      color: DarkKickColors.darkBackground,
      child: SafeArea(
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
              child: ColoredBox(
                color: DarkKickColors.darkBackground,
                child: chatsState.when(
                  data: _buildChatsList,
                  loading: _buildLoadingState,
                  error: (error, _) => _buildErrorState(error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: Row(
        children: [
          const SizedBox(width: 42),
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
            onTap: _openNewChat,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: DarkKickColors.panel.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DarkKickColors.stroke, width: 0.8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              color: DarkKickColors.electricPurple,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: DarkKickColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: const InputDecoration(
                  hintText: 'Поиск',
                  hintStyle: TextStyle(
                    color: DarkKickColors.textTertiary,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
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
              const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesList(List<Chat> chats) {
    final currentUserId = _currentUserId;
    final personalChats = currentUserId == null
        ? const <Chat>[]
        : chats
              .where(
                (chat) =>
                    _isDirectChat(chat) &&
                    chat.participants.contains(currentUserId),
              )
              .take(8)
              .toList();

    if (personalChats.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 86,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: personalChats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final chat = personalChats[index];
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
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
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? DarkKickColors.neonPurple.withValues(alpha: 0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: isSelected
                          ? DarkKickColors.neonPurple
                          : DarkKickColors.divider,
                      width: 0.8,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: DarkKickColors.neonPurple.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 14,
                            ),
                          ]
                        : null,
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
    final hasHumanChats = chats.any((chat) => !SystemBot.isSystemChat(chat));
    final shouldShowFindFriendState =
        _selectedFilterIndex == 0 && _searchQuery.isEmpty && !hasHumanChats;

    if (chats.isEmpty) {
      final empty = _emptyStateForFilter();
      return _EmptyState(
        title: empty.title,
        subtitle: empty.subtitle,
        icon: empty.icon,
        actionLabel: _selectedFilterIndex <= 1 ? 'Начать чат' : null,
        onAction: _selectedFilterIndex <= 1 ? _openNewChat : null,
      );
    }

    return CustomScrollView(
      primary: false,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index.isOdd) return const SizedBox(height: 10);
              final chat = chats[index ~/ 2];
              final isSystemBotChat = SystemBot.isSystemChat(chat);
              return _ChatTile(
                chat: chat,
                isDirectChat: !isSystemBotChat && _isDirectLikeChat(chat),
                isSystemBotChat: isSystemBotChat,
                currentUserId: currentUserId,
                fallbackTitle: _fallbackTitle(chat),
                onTap: () => _openChat(chat),
              );
            }, childCount: chats.length * 2 - 1),
          ),
        ),
        if (shouldShowFindFriendState)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: _FindFriendCard(onTap: _openNewChat),
            ),
          ),
      ],
    );
  }

  List<Chat> _filterChats(List<Chat> chats) {
    final currentUserId = _currentUserId;
    var filtered = currentUserId == null
        ? const <Chat>[]
        : chats
              .where((chat) => chat.participants.contains(currentUserId))
              .where((chat) => _isDisplayableChat(chat, currentUserId))
              .toList();
    if (_selectedFilterIndex == 1) {
      filtered = filtered.where(_isDirectLikeChat).toList();
    } else if (_selectedFilterIndex == 2) {
      filtered = filtered.where(_isGroupChat).toList();
    } else if (_selectedFilterIndex == 3) {
      filtered = filtered.where(_isChannelChat).toList();
    }

    if (_searchQuery.isEmpty) return filtered;
    return filtered
        .where(
          (chat) => _fallbackTitle(chat).toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  bool _isDirectChat(Chat chat) {
    final type = chat.type.toLowerCase().trim();
    return type == 'direct' || type == 'private';
  }

  bool _isDirectLikeChat(Chat chat) {
    final type = chat.type.toLowerCase().trim();
    return type == 'direct' ||
        type == 'private' ||
        (!chat.isGroup && type.isEmpty && chat.participants.length == 2);
  }

  bool _isDisplayableChat(Chat chat, String currentUserId) {
    if (chat.id.trim().isEmpty ||
        chat.participants.isEmpty ||
        !chat.participants.contains(currentUserId)) {
      _logSkippedLegacyChat(chat, currentUserId, 'invalid id/participants');
      return false;
    }
    if (SystemBot.isSystemChat(chat)) {
      final validSystemChat = chat.participants.contains(SystemBot.uid);
      if (!validSystemChat) {
        _logSkippedLegacyChat(chat, currentUserId, 'invalid system bot chat');
      }
      return validSystemChat;
    }
    if (_isDirectLikeChat(chat)) {
      final uniqueParticipants = chat.participants.toSet();
      if (uniqueParticipants.length != 2) {
        _logSkippedLegacyChat(chat, currentUserId, 'invalid direct participants');
        return false;
      }
      final hasPeer = chat.otherParticipantId(currentUserId) != null;
      if (!hasPeer) {
        _logSkippedLegacyChat(chat, currentUserId, 'missing direct peer');
      }
      return hasPeer;
    }
    if (!_isGroupChat(chat) && !_isChannelChat(chat)) {
      _logSkippedLegacyChat(chat, currentUserId, 'unknown legacy chat type');
      return false;
    }
    final hasTitle = _fallbackTitle(chat).trim().isNotEmpty;
    if (!hasTitle) {
      _logSkippedLegacyChat(chat, currentUserId, 'empty display title');
    }
    return hasTitle;
  }

  void _logSkippedLegacyChat(Chat chat, String currentUserId, String reason) {
    assert(() {
      debugPrint(
        'Darkkick skipped legacy chat ${chat.id}: $reason; '
        'type=${chat.type}; participants=${chat.participants}; '
        'currentUserId=$currentUserId',
      );
      return true;
    }());
  }

  bool _isGroupChat(Chat chat) {
    final type = chat.type.toLowerCase().trim();
    return chat.isGroup || type == 'group';
  }

  bool _isChannelChat(Chat chat) {
    return chat.type.toLowerCase().trim() == 'channel';
  }

  _FilterEmptyState _emptyStateForFilter() {
    return switch (_selectedFilterIndex) {
      1 => const _FilterEmptyState(
        title: 'Личных чатов пока нет',
        subtitle: 'Найди человека через верхнюю кнопку и начни диалог.',
        icon: Icons.person_outline,
      ),
      2 => const _FilterEmptyState(
        title: 'Групп пока нет',
        subtitle: 'Групповые чаты появятся здесь, когда будут созданы.',
        icon: Icons.groups_2_outlined,
      ),
      3 => const _FilterEmptyState(
        title: 'Каналов пока нет',
        subtitle: 'Каналы появятся здесь, если в данных будет type = channel.',
        icon: Icons.campaign_outlined,
      ),
      _ => const _FilterEmptyState(
        title: 'Здесь пока пусто',
        subtitle: 'Создай чат через верхнюю кнопку справа.',
        icon: Icons.chat_bubble_outline,
      ),
    };
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
    const items = [
      _DarkkickNavDestination(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Чаты',
      ),
      _DarkkickNavDestination(
        icon: Icons.phone_outlined,
        activeIcon: Icons.phone,
        label: 'Звонки',
      ),
      _DarkkickNavDestination(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Люди',
      ),
      _DarkkickNavDestination(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Профиль',
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: const Color(0xFF0B0814).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.075),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF12101D).withValues(alpha: 0.9),
                const Color(0xFF07050C).withValues(alpha: 0.92),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: DarkKickColors.neonPurple.withValues(alpha: 0.08),
                blurRadius: 28,
                spreadRadius: -8,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              final selected = index == _selectedNavIndex;
              return Expanded(
                child: _DarkkickBottomNavItem(
                  item: items[index],
                  selected: selected,
                  onTap: () => setState(() => _selectedNavIndex = index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  String _fallbackTitle(Chat chat) {
    if (SystemBot.isSystemChat(chat)) return SystemBot.name;
    final raw = (chat.groupName ?? chat.name).trim();
    if (raw.isNotEmpty) return raw;
    if (_isGroupChat(chat)) return 'Группа';
    if (_isChannelChat(chat)) return 'Канал';
    return 'Чат';
  }

  void _openChat(Chat chat) {
    Navigator.push(
      context,
      NavigationAnimations.slideFadeRoute(
        SingleChatScreen(
          chatId: chat.id,
          chatName: _fallbackTitle(chat),
          otherUserId: SystemBot.isSystemChat(chat)
              ? SystemBot.uid
              : chat.otherParticipantId(_currentUserId),
        ),
      ),
    );
  }

  void _openNewChat() {
    Navigator.push(
      context,
      NavigationAnimations.slideFadeRoute(const NewChatScreen()),
    );
  }
}

class _DarkkickNavDestination {
  const _DarkkickNavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _DarkkickBottomNavItem extends StatelessWidget {
  const _DarkkickBottomNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _DarkkickNavDestination item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? DarkKickColors.electricPurple
        : DarkKickColors.textTertiary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 32 : 0,
                height: 3,
                margin: const EdgeInsets.only(top: 7),
                decoration: BoxDecoration(
                  color: DarkKickColors.electricPurple,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: DarkKickColors.neonPurple.withValues(
                              alpha: 0.32,
                            ),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        color: color,
                        size: selected ? 25 : 24,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.chat,
    required this.isDirectChat,
    required this.isSystemBotChat,
    required this.currentUserId,
    required this.fallbackTitle,
    required this.onTap,
  });

  final Chat chat;
  final bool isDirectChat;
  final bool isSystemBotChat;
  final String? currentUserId;
  final String fallbackTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final otherUserId = isDirectChat
        ? chat.otherParticipantId(currentUserId)
        : null;

    return StreamBuilder<_PeerMeta>(
      stream: _peerMetaStream(otherUserId),
      builder: (context, snapshot) {
        final meta = snapshot.data;
        final title = isSystemBotChat
            ? SystemBot.name
            : isDirectChat
            ? meta?.name ?? fallbackTitle
            : fallbackTitle;
        final photoUrl = isDirectChat ? meta?.photoUrl : null;
        final preview = chat.lastMessage.trim().isEmpty
            ? 'Сообщений пока нет'
            : chat.lastMessage;
        final presence = meta == null || !isDirectChat
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
                color: DarkKickColors.panel.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: DarkKickColors.divider, width: 0.8),
              ),
              child: Row(
                children: [
                  isSystemBotChat
                      ? const _SystemBotAvatar(size: 52)
                      : _ChatAvatar(
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
                            if (isSystemBotChat)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.verified_rounded,
                                  color: DarkKickColors.electricPurple,
                                  size: 15,
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
                          preview,
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

class _SystemBotAvatar extends StatelessWidget {
  const _SystemBotAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: DarkKickColors.electricPurple, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          SystemBot.avatarAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: DarkKickColors.cardSoft,
            child: Center(
              child: Icon(
                Icons.verified_rounded,
                color: DarkKickColors.electricPurple,
              ),
            ),
          ),
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
        border: Border.all(color: DarkKickColors.stroke, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.14),
            blurRadius: 10,
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
      .collection('publicProfiles')
      .doc(uid)
      .snapshots()
      .map((doc) {
        final data = doc.data() ?? const <String, dynamic>{};
        final email = (data['email'] ?? '').toString();
        final fallback = email.contains('@')
            ? email.split('@').first
            : 'Пользователь';
        final loadedName = (data['name'] ?? fallback).toString().trim();
        final name = loadedName.isEmpty ? fallback : loadedName;
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
          border: Border.all(color: DarkKickColors.stroke, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: DarkKickColors.neonPurple.withValues(alpha: 0.12),
              blurRadius: 12,
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
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              _StartChatButton(label: actionLabel!, onTap: onAction!),
            ],
          ],
        ),
      ),
    );
  }
}

class _FindFriendCard extends StatelessWidget {
  const _FindFriendCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DarkKickColors.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.08),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_search_outlined,
            color: DarkKickColors.electricPurple,
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            'Найди друга по тегу',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _StartChatButton(label: 'Начать чат', onTap: onTap),
        ],
      ),
    );
  }
}

class _StartChatButton extends StatelessWidget {
  const _StartChatButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF241050), Color(0xFF7B2CBF), Color(0xFF2E0C61)],
          ),
          boxShadow: [
            BoxShadow(
              color: DarkKickColors.neonPurple.withValues(alpha: 0.24),
              blurRadius: 16,
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: const Icon(Icons.add_comment_outlined, size: 18),
          label: Text(label),
        ),
      ),
    );
  }
}

class _FilterEmptyState {
  const _FilterEmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
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
    return ColoredBox(
      color: DarkKickColors.darkBackground,
      child: SafeArea(
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
      ),
    );
  }
}
