import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/system_bot.dart';
import '../models/chat.dart';
import '../providers/chats_provider.dart';
import '../services/desktop_platform_service.dart';
import '../theme/darkkick_colors.dart';
import '../utils/time_formatter.dart';
import 'single_chat_screen.dart';

class DarkkickDesktopWorkspace extends ConsumerStatefulWidget {
  const DarkkickDesktopWorkspace({
    super.key,
    required this.currentUserId,
    required this.onOpenNewChat,
  });

  final String? currentUserId;
  final VoidCallback onOpenNewChat;

  @override
  ConsumerState<DarkkickDesktopWorkspace> createState() =>
      _DarkkickDesktopWorkspaceState();
}

enum _DesktopSection { home, conversations, calls, files, settings }

enum _ConversationTab { chat, media, files, calls, profile }

class _DarkkickDesktopWorkspaceState
    extends ConsumerState<DarkkickDesktopWorkspace> {
  static const double _minInspectorWidth = 260;
  static const double _maxInspectorWidth = 420;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  _DesktopSection _section = _DesktopSection.home;
  _ConversationTab _conversationTab = _ConversationTab.chat;
  Chat? _activeChat;
  double _inspectorWidth = 318;
  String _searchQuery = '';

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
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatsState = ref.watch(chatsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: DarkKickColors.deepBackground,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: DarkKickColors.deepBackground,
        systemNavigationBarDividerColor: DarkKickColors.deepBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: DarkKickColors.deepBackground,
        body: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.keyN, control: true):
                widget.onOpenNewChat,
            const SingleActivator(LogicalKeyboardKey.keyK, control: true):
                _focusHomeSearch,
            const SingleActivator(LogicalKeyboardKey.keyR, control: true): () =>
                ref.invalidate(chatsProvider),
            const SingleActivator(LogicalKeyboardKey.escape): _goHome,
          },
          child: Focus(
            autofocus: true,
            child: Row(
              children: [
                _DesktopRail(
                  section: _section,
                  onSectionSelected: _selectSection,
                ),
                Expanded(
                  child: chatsState.when(
                    data: _buildLoadedShell,
                    loading: _buildLoadingShell,
                    error: (error, _) => _buildErrorShell(error),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedShell(List<Chat> allChats) {
    final chats = _visibleChats(allChats);
    final activeChat = _resolvedActiveChat(chats);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DarkKickColors.deepBackground,
            Color(0xFF07050C),
            Color(0xFF090612),
          ],
        ),
      ),
      child: switch (_section) {
        _DesktopSection.home => _buildHome(chats),
        _DesktopSection.conversations =>
          activeChat == null
              ? _buildConversationGallery(chats)
              : _buildConversationWorkspace(activeChat, chats),
        _DesktopSection.calls => _buildCallsHub(chats),
        _DesktopSection.files => _buildFilesHub(chats),
        _DesktopSection.settings => _buildSettingsHub(),
      },
    );
  }

  Widget _buildLoadingShell() {
    return const ColoredBox(
      color: DarkKickColors.deepBackground,
      child: Center(
        child: CircularProgressIndicator(color: DarkKickColors.neonPurple),
      ),
    );
  }

  Widget _buildErrorShell(Object error) {
    return ColoredBox(
      color: DarkKickColors.deepBackground,
      child: Center(
        child: _DesktopEmptyCard(
          icon: Icons.cloud_off_outlined,
          title: 'Workspace offline',
          subtitle: 'DARKKICK could not load your desktop workspace.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(chatsProvider),
        ),
      ),
    );
  }

  Widget _buildHome(List<Chat> chats) {
    final continued = chats.take(8).toList();
    final mediaChats = chats
        .where((chat) => chat.lastMessageType.toLowerCase() == 'image')
        .take(5)
        .toList();
    final fileChats = chats
        .where((chat) => _looksLikeFileActivity(chat.lastMessageType))
        .take(5)
        .toList();
    final favorites = chats.where(_isDirectLikeChat).take(6).toList();

    return _DesktopPageScaffold(
      title: 'Home',
      subtitle: 'A people-centered communication workspace.',
      trailing: _TopBarButton(
        icon: Icons.add_comment_outlined,
        label: 'New',
        onTap: widget.onOpenNewChat,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1120;
          final content = [
            _buildWelcomeSurface(chats),
            const SizedBox(height: 28),
            _DashboardSection(
              title: 'Continue Conversations',
              actionIcon: Icons.arrow_forward_rounded,
              onAction: () => _selectSection(_DesktopSection.conversations),
              child: continued.isEmpty
                  ? _DesktopEmptyCard(
                      icon: Icons.mode_comment_outlined,
                      title: 'No active conversations',
                      subtitle: 'Start a private workspace from DARKKICK.',
                      actionLabel: 'Start',
                      onAction: widget.onOpenNewChat,
                    )
                  : SizedBox(
                      height: 190,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: continued.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final chat = continued[index];
                          return _ConversationCard(
                            chat: chat,
                            title: _titleFor(chat),
                            currentUserId: widget.currentUserId,
                            selected: _activeChat?.id == chat.id,
                            onTap: () => _openConversation(chat),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 28),
            _DashboardSection(
              title: 'Recent Media',
              actionIcon: Icons.photo_library_outlined,
              onAction: () => _selectWorkspaceTab(_ConversationTab.media),
              child: _MediaPreviewGrid(
                chats: mediaChats,
                titleFor: _titleFor,
                onOpen: _openConversation,
              ),
            ),
          ];

          final side = [
            _DashboardSection(
              title: 'Active Calls',
              child: _CallStatusCard(onTap: _showDesktopUnavailable),
            ),
            const SizedBox(height: 22),
            _DashboardSection(
              title: 'Favorite Contacts',
              child: _FavoriteContactsGrid(
                chats: favorites,
                titleFor: _titleFor,
                onOpen: _openConversation,
              ),
            ),
            const SizedBox(height: 22),
            _DashboardSection(
              title: 'Recent Files',
              actionIcon: Icons.folder_open_outlined,
              onAction: () => _selectSection(_DesktopSection.files),
              child: _RecentFilesStrip(
                chats: fileChats,
                titleFor: _titleFor,
                onOpen: _openConversation,
              ),
            ),
          ];

          if (!wide) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 34),
              children: [...content, const SizedBox(height: 28), ...side],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(34, 0, 34, 34),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: content,
                    ),
                  ),
                  const SizedBox(width: 28),
                  SizedBox(
                    width: 356,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: side,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSurface(List<Chat> chats) {
    final unread = chats.fold<int>(
      0,
      (total, chat) => total + chat.unreadFor(widget.currentUserId),
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 168),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        image: const DecorationImage(
          image: AssetImage('assets/images/darkkick_app_icon.png'),
          fit: BoxFit.contain,
          alignment: Alignment.centerRight,
          opacity: 0.16,
        ),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: -18,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DARKKICK Desktop',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Open conversations as workspaces, not message queues.',
                  style: TextStyle(
                    color: DarkKickColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricPill(
                      icon: Icons.forum_outlined,
                      label: '${chats.length} spaces',
                    ),
                    _MetricPill(
                      icon: Icons.mark_chat_unread_outlined,
                      label: '$unread unread',
                    ),
                    const _MetricPill(
                      icon: Icons.desktop_windows_outlined,
                      label: 'Windows mode',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: _DesktopSearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onSubmitted: _openFirstSearchResult,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationGallery(List<Chat> chats) {
    final filtered = _searchQuery.isEmpty
        ? chats
        : chats
              .where(
                (chat) => _titleFor(chat).toLowerCase().contains(_searchQuery),
              )
              .toList();

    return _DesktopPageScaffold(
      title: 'Conversations',
      subtitle: 'Pick a person or group to open a workspace.',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 320,
            child: _DesktopSearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onSubmitted: _openFirstSearchResult,
            ),
          ),
          const SizedBox(width: 12),
          _TopBarButton(
            icon: Icons.add_comment_outlined,
            label: 'New',
            onTap: widget.onOpenNewChat,
          ),
        ],
      ),
      child: filtered.isEmpty
          ? Center(
              child: _DesktopEmptyCard(
                icon: Icons.search_off_outlined,
                title: 'Nothing matched',
                subtitle: 'Try another name or start a new conversation.',
                actionLabel: 'New conversation',
                onAction: widget.onOpenNewChat,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(34, 0, 34, 34),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisExtent: 190,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final chat = filtered[index];
                return _ConversationCard(
                  chat: chat,
                  title: _titleFor(chat),
                  currentUserId: widget.currentUserId,
                  selected: _activeChat?.id == chat.id,
                  onTap: () => _openConversation(chat),
                );
              },
            ),
    );
  }

  Widget _buildConversationWorkspace(Chat chat, List<Chat> chats) {
    return Column(
      children: [
        _WorkspaceHeader(
          chat: chat,
          title: _titleFor(chat),
          currentUserId: widget.currentUserId,
          tab: _conversationTab,
          onBackHome: _goHome,
          onTabSelected: (tab) => setState(() => _conversationTab = tab),
          onRefresh: () => ref.invalidate(chatsProvider),
          onOpenNewChat: widget.onOpenNewChat,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
            child: Row(
              children: [
                Expanded(child: _buildWorkspaceBody(chat, chats)),
                _InspectorResizeHandle(
                  onDelta: (delta) {
                    setState(() {
                      _inspectorWidth = (_inspectorWidth - delta).clamp(
                        _minInspectorWidth,
                        _maxInspectorWidth,
                      );
                    });
                  },
                ),
                SizedBox(
                  width: _inspectorWidth,
                  child: _WorkspaceInspector(
                    chat: chat,
                    title: _titleFor(chat),
                    currentUserId: widget.currentUserId,
                    onOpenFiles: () => setState(
                      () => _conversationTab = _ConversationTab.files,
                    ),
                    onUnsupported: _showDesktopUnavailable,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceBody(Chat chat, List<Chat> chats) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: switch (_conversationTab) {
        _ConversationTab.chat => _ChatWorkspaceCard(
          key: ValueKey('chat-${chat.id}'),
          child: SingleChatScreen(
            key: ValueKey('desktop-chat-${chat.id}'),
            chatId: chat.id,
            chatName: _titleFor(chat),
            otherUserId: SystemBot.isSystemChat(chat)
                ? SystemBot.uid
                : chat.otherParticipantId(widget.currentUserId),
            embedded: true,
          ),
        ),
        _ConversationTab.media => _WorkspaceDeck(
          key: ValueKey('media-${chat.id}'),
          title: 'Media Board',
          subtitle: 'Large previews for shared photos and visual context.',
          children: [
            _LargePreviewTile(
              icon: Icons.photo_library_outlined,
              title: chat.lastMessageType == 'image'
                  ? 'Latest shared image'
                  : 'No recent media',
              subtitle: _titleFor(chat),
              accent: const Color(0xFF7DD3FC),
            ),
            _LargePreviewTile(
              icon: Icons.grid_view_rounded,
              title: 'Gallery slots',
              subtitle: 'Media history stays in this workspace tab.',
              accent: DarkKickColors.neonPurple,
            ),
            _LargePreviewTile(
              icon: Icons.fullscreen_rounded,
              title: 'Large preview mode',
              subtitle: 'Desktop review surface for images and files.',
              accent: const Color(0xFF47FF93),
            ),
          ],
        ),
        _ConversationTab.files => _WorkspaceDeck(
          key: ValueKey('files-${chat.id}'),
          title: 'Files',
          subtitle: 'Shared documents, archives and attachments.',
          children: [
            _FilePreviewTile(
              icon: Icons.archive_outlined,
              title: 'Conversation archive',
              subtitle: 'Files uploaded here appear as desktop cards.',
            ),
            _FilePreviewTile(
              icon: Icons.upload_file_outlined,
              title: 'Desktop upload path',
              subtitle:
                  'Use the attachment button in Chat for safe Windows send.',
            ),
            _FilePreviewTile(
              icon: Icons.folder_special_outlined,
              title: 'Rich previews',
              subtitle: 'Preview state is separated from the message timeline.',
            ),
          ],
        ),
        _ConversationTab.calls => _WorkspaceDeck(
          key: ValueKey('calls-${chat.id}'),
          title: 'Calls',
          subtitle: 'Voice recording is disabled on Windows until stable.',
          children: [
            _LargePreviewTile(
              icon: Icons.phone_disabled_outlined,
              title: 'Not available on desktop yet',
              subtitle: DesktopPlatformService.unsupportedDesktopMessage,
              accent: DarkKickColors.pending,
              onTap: _showDesktopUnavailable,
            ),
            _LargePreviewTile(
              icon: Icons.history_toggle_off_outlined,
              title: 'Call history',
              subtitle: 'Desktop call records will live here.',
              accent: const Color(0xFF7DD3FC),
            ),
          ],
        ),
        _ConversationTab.profile => _WorkspaceDeck(
          key: ValueKey('profile-${chat.id}'),
          title: 'Profile',
          subtitle: 'Workspace identity and participant details.',
          children: [
            _ProfileIdentityTile(
              title: _titleFor(chat),
              chat: chat,
              currentUserId: widget.currentUserId,
            ),
            _FilePreviewTile(
              icon: Icons.verified_user_outlined,
              title: SystemBot.isSystemChat(chat)
                  ? 'Official space'
                  : 'Private space',
              subtitle:
                  '${chat.participants.length} participant${chat.participants.length == 1 ? '' : 's'}',
            ),
          ],
        ),
      },
    );
  }

  Widget _buildCallsHub(List<Chat> chats) {
    return _DesktopPageScaffold(
      title: 'Calls',
      subtitle: 'Desktop calling controls stay isolated from mobile plugins.',
      trailing: _TopBarButton(
        icon: Icons.phone_disabled_outlined,
        label: 'Unavailable',
        onTap: _showDesktopUnavailable,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(34, 0, 34, 34),
        children: [
          SizedBox(
            height: 430,
            child: _WorkspaceDeck(
              title: 'Active Calls',
              subtitle: 'No active desktop calls.',
              children: [
                _LargePreviewTile(
                  icon: Icons.phone_disabled_outlined,
                  title: 'Not available on desktop yet',
                  subtitle: DesktopPlatformService.unsupportedDesktopMessage,
                  accent: DarkKickColors.pending,
                  onTap: _showDesktopUnavailable,
                ),
                _LargePreviewTile(
                  icon: Icons.groups_2_outlined,
                  title: '${math.min(chats.length, 12)} ready spaces',
                  subtitle: 'Conversations can become call workspaces later.',
                  accent: const Color(0xFF7DD3FC),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesHub(List<Chat> chats) {
    final fileChats = chats
        .where((chat) => _looksLikeFileActivity(chat.lastMessageType))
        .take(12)
        .toList();

    return _DesktopPageScaffold(
      title: 'Files',
      subtitle: 'A desktop-first library for shared attachments.',
      trailing: _TopBarButton(
        icon: Icons.refresh_rounded,
        label: 'Refresh',
        onTap: () => ref.invalidate(chatsProvider),
      ),
      child: fileChats.isEmpty
          ? Center(
              child: _DesktopEmptyCard(
                icon: Icons.folder_open_outlined,
                title: 'No desktop files yet',
                subtitle:
                    'Attachments sent from conversations will appear here.',
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(34, 0, 34, 34),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisExtent: 148,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: fileChats.length,
              itemBuilder: (context, index) {
                final chat = fileChats[index];
                return _FilePreviewTile(
                  icon: _fileIconFor(chat.lastMessageType),
                  title: _messagePreview(chat),
                  subtitle: _titleFor(chat),
                  onTap: () {
                    _openConversation(chat);
                    setState(() => _conversationTab = _ConversationTab.files);
                  },
                );
              },
            ),
    );
  }

  Widget _buildSettingsHub() {
    return _DesktopPageScaffold(
      title: 'Settings',
      subtitle: 'Desktop behavior and workspace safety.',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(34, 0, 34, 34),
        children: [
          SizedBox(
            height: 430,
            child: _WorkspaceDeck(
              title: 'Windows Desktop Mode',
              subtitle: 'DARKKICK is running the safe desktop platform path.',
              children: [
                const _FilePreviewTile(
                  icon: Icons.stream_outlined,
                  title: 'Realtime snapshots avoided',
                  subtitle:
                      'Open chats use polling to protect Windows stability.',
                ),
                const _FilePreviewTile(
                  icon: Icons.image_outlined,
                  title: 'Bytes-based media picking',
                  subtitle:
                      'Photos are selected through a desktop-safe picker.',
                ),
                _FilePreviewTile(
                  icon: Icons.mic_off_outlined,
                  title: 'Voice recording paused',
                  subtitle: DesktopPlatformService.unsupportedDesktopMessage,
                  onTap: _showDesktopUnavailable,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Chat> _visibleChats(List<Chat> chats) {
    final userId = widget.currentUserId;
    if (userId == null || userId.isEmpty) return const [];

    return chats
        .where((chat) => chat.participants.contains(userId))
        .where((chat) => _isDisplayableChat(chat, userId))
        .toList();
  }

  Chat? _resolvedActiveChat(List<Chat> chats) {
    final selected = _activeChat;
    if (selected == null) return null;

    for (final chat in chats) {
      if (chat.id == selected.id) return chat;
    }
    return selected.id.isEmpty ? null : selected;
  }

  void _selectSection(_DesktopSection section) {
    setState(() => _section = section);
  }

  void _selectWorkspaceTab(_ConversationTab tab) {
    final active = _activeChat;
    if (active == null) {
      setState(() => _section = _DesktopSection.conversations);
      return;
    }
    setState(() {
      _section = _DesktopSection.conversations;
      _conversationTab = tab;
    });
  }

  void _openConversation(Chat chat) {
    setState(() {
      _activeChat = chat;
      _section = _DesktopSection.conversations;
      _conversationTab = _ConversationTab.chat;
    });
  }

  void _focusHomeSearch() {
    setState(() => _section = _DesktopSection.home);
    _searchFocusNode.requestFocus();
  }

  void _goHome() {
    setState(() => _section = _DesktopSection.home);
  }

  void _openFirstSearchResult(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return;

    final chats = ref.read(chatsProvider).valueOrNull ?? const <Chat>[];
    for (final chat in _visibleChats(chats)) {
      if (_titleFor(chat).toLowerCase().contains(query)) {
        _openConversation(chat);
        return;
      }
    }
  }

  void _showDesktopUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(DesktopPlatformService.unsupportedDesktopMessage)),
    );
  }

  bool _isDisplayableChat(Chat chat, String currentUserId) {
    if (chat.id.trim().isEmpty ||
        chat.participants.isEmpty ||
        !chat.participants.contains(currentUserId)) {
      return false;
    }

    if (SystemBot.isSystemChat(chat)) {
      return chat.participants.contains(SystemBot.uid);
    }

    if (_isDirectLikeChat(chat)) {
      final uniqueParticipants = chat.participants.toSet();
      return uniqueParticipants.length == 2 &&
          chat.otherParticipantId(currentUserId) != null;
    }

    return _isGroupChat(chat) || _isChannelChat(chat);
  }

  bool _isDirectLikeChat(Chat chat) {
    final type = chat.type.toLowerCase().trim();
    return type == 'direct' ||
        type == 'private' ||
        (!chat.isGroup && type.isEmpty && chat.participants.length == 2);
  }

  bool _isGroupChat(Chat chat) {
    final type = chat.type.toLowerCase().trim();
    return chat.isGroup || type == 'group';
  }

  bool _isChannelChat(Chat chat) {
    return chat.type.toLowerCase().trim() == 'channel';
  }

  bool _looksLikeFileActivity(String type) {
    final normalized = type.toLowerCase().trim();
    return normalized == 'file' ||
        normalized == 'document' ||
        normalized == 'voice' ||
        normalized == 'audio';
  }

  String _titleFor(Chat chat) {
    if (SystemBot.isSystemChat(chat)) return SystemBot.name;
    final raw = (chat.groupName ?? chat.name).trim();
    if (raw.isNotEmpty) return raw;
    if (_isGroupChat(chat)) return 'Group';
    if (_isChannelChat(chat)) return 'Channel';
    return 'Conversation';
  }

  String _messagePreview(Chat chat) {
    final text = chat.lastMessage.trim();
    if (text.isNotEmpty) return text;

    return switch (chat.lastMessageType.toLowerCase()) {
      'image' => 'Image',
      'sticker' => 'Sticker',
      'voice' || 'audio' => 'Audio message',
      'file' || 'document' => 'File',
      _ => 'No messages yet',
    };
  }

  IconData _fileIconFor(String type) {
    return switch (type.toLowerCase()) {
      'image' => Icons.image_outlined,
      'voice' || 'audio' => Icons.graphic_eq_outlined,
      'document' || 'file' => Icons.description_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({required this.section, required this.onSectionSelected});

  final _DesktopSection section;
  final ValueChanged<_DesktopSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      _RailItemData(_DesktopSection.home, Icons.grid_view_rounded, 'Home'),
      _RailItemData(
        _DesktopSection.conversations,
        Icons.forum_outlined,
        'Conversations',
      ),
      _RailItemData(_DesktopSection.calls, Icons.call_outlined, 'Calls'),
      _RailItemData(_DesktopSection.files, Icons.folder_outlined, 'Files'),
    ];

    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF030207),
        border: Border(right: BorderSide(color: Color(0xFF17111F))),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const _DesktopLogoMark(),
            const SizedBox(height: 26),
            ...items.map(
              (item) => _RailItem(
                item: item,
                selected: item.section == section,
                onTap: () => onSectionSelected(item.section),
              ),
            ),
            const Spacer(),
            _RailItem(
              item: _RailItemData(
                _DesktopSection.settings,
                Icons.settings_outlined,
                'Settings',
              ),
              selected: section == _DesktopSection.settings,
              onTap: () => onSectionSelected(_DesktopSection.settings),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _RailItemData {
  const _RailItemData(this.section, this.icon, this.label);

  final _DesktopSection section;
  final IconData icon;
  final String label;
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _RailItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : DarkKickColors.textTertiary;

    return Tooltip(
      message: item.label,
      waitDuration: const Duration(milliseconds: 350),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 60,
          height: 58,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? DarkKickColors.neonPurple.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? DarkKickColors.neonPurple.withValues(alpha: 0.44)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                color: selected ? DarkKickColors.electricPurple : color,
                size: 21,
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
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

class _DesktopLogoMark extends StatelessWidget {
  const _DesktopLogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: DarkKickColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: DarkKickColors.neonPurple.withValues(alpha: 0.5),
        ),
        image: const DecorationImage(
          image: AssetImage('assets/images/darkkick_app_icon.png'),
          fit: BoxFit.cover,
          opacity: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: DarkKickColors.neonPurple.withValues(alpha: 0.25),
            blurRadius: 18,
            spreadRadius: -6,
          ),
        ],
      ),
    );
  }
}

class _DesktopPageScaffold extends StatelessWidget {
  const _DesktopPageScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(34, 26, 34, 22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: DarkKickColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _DesktopSearchField extends StatelessWidget {
  const _DesktopSearchField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: DarkKickColors.textPrimary, fontSize: 14),
      cursorColor: DarkKickColors.neonPurple,
      decoration: InputDecoration(
        hintText: 'Search workspace',
        hintStyle: const TextStyle(color: DarkKickColors.textTertiary),
        prefixIcon: const Icon(
          Icons.search,
          color: DarkKickColors.textTertiary,
          size: 19,
        ),
        suffixIcon: const Padding(
          padding: EdgeInsets.only(right: 10),
          child: _ShortcutHint(label: 'Ctrl K'),
        ),
        filled: true,
        fillColor: const Color(0xFF0C0912),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DarkKickColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DarkKickColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DarkKickColors.neonPurple),
        ),
      ),
    );
  }
}

class _ShortcutHint extends StatelessWidget {
  const _ShortcutHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      widthFactor: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: DarkKickColors.deepBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: DarkKickColors.divider),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: DarkKickColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.title,
    required this.child,
    this.actionIcon,
    this.onAction,
  });

  final String title;
  final Widget child;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (actionIcon != null && onAction != null)
              Tooltip(
                message: title,
                child: IconButton(
                  onPressed: onAction,
                  icon: Icon(actionIcon, size: 18),
                  color: DarkKickColors.textSecondary,
                  style: IconButton.styleFrom(
                    fixedSize: const Size(34, 34),
                    backgroundColor: DarkKickColors.panel.withValues(
                      alpha: 0.72,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: DarkKickColors.divider),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.chat,
    required this.title,
    required this.currentUserId,
    required this.selected,
    required this.onTap,
  });

  final Chat chat;
  final String title;
  final String? currentUserId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = chat.unreadFor(currentUserId);
    final color = _avatarColor(title);

    return Tooltip(
      message: 'Open $title',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? DarkKickColors.cardSoft.withValues(alpha: 0.95)
                : DarkKickColors.panel.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? DarkKickColors.neonPurple.withValues(alpha: 0.66)
                  : Colors.white.withValues(alpha: 0.07),
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? DarkKickColors.neonPurple.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.24),
                blurRadius: selected ? 24 : 18,
                spreadRadius: -10,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _DesktopAvatar(
                    title: title,
                    color: color,
                    isGroup: chat.isGroup,
                    isOfficial: SystemBot.isSystemChat(chat),
                    size: 46,
                  ),
                  const Spacer(),
                  if (unread > 0)
                    _DesktopBadge(label: unread > 99 ? '99+' : '$unread')
                  else
                    const Icon(
                      Icons.arrow_outward_rounded,
                      color: DarkKickColors.textTertiary,
                      size: 18,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _previewText(chat),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DarkKickColors.textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _TypeChip(type: chat.lastMessageType),
                  const Spacer(),
                  Text(
                    TimeFormatter.formatChatTime(chat.lastMessageTime),
                    style: const TextStyle(
                      color: DarkKickColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _previewText(Chat chat) {
    final text = chat.lastMessage.trim();
    return text.isEmpty ? 'No messages yet' : text;
  }

  Color _avatarColor(String value) {
    final hash = value.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    const colors = [
      Color(0xFF2E2A7F),
      Color(0xFF7C3AED),
      Color(0xFF0F766E),
      Color(0xFF9A3412),
      Color(0xFF334155),
    ];
    return colors[hash % colors.length];
  }
}

class _DesktopAvatar extends StatelessWidget {
  const _DesktopAvatar({
    required this.title,
    required this.color,
    required this.isGroup,
    required this.isOfficial,
    required this.size,
  });

  final String title;
  final Color color;
  final bool isGroup;
  final bool isOfficial;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = title.trim().isEmpty ? '?' : title.trim()[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOfficial
              ? DarkKickColors.electricPurple
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: isOfficial
            ? Image.asset(
                SystemBot.avatarAsset,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.verified_rounded, color: Colors.white),
              )
            : isGroup
            ? Icon(
                Icons.groups_2_outlined,
                color: Colors.white.withValues(alpha: 0.92),
                size: size * 0.42,
              )
            : Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final normalized = type.trim().isEmpty ? 'text' : type.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: DarkKickColors.deepBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: DarkKickColors.divider),
      ),
      child: Text(
        normalized,
        style: const TextStyle(
          color: DarkKickColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DesktopBadge extends StatelessWidget {
  const _DesktopBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DarkKickColors.neonPurple,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: DarkKickColors.deepBackground.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DarkKickColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: DarkKickColors.electricPurple, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: DarkKickColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  const _TopBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: DarkKickColors.neonPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _MediaPreviewGrid extends StatelessWidget {
  const _MediaPreviewGrid({
    required this.chats,
    required this.titleFor,
    required this.onOpen,
  });

  final List<Chat> chats;
  final String Function(Chat chat) titleFor;
  final ValueChanged<Chat> onOpen;

  @override
  Widget build(BuildContext context) {
    if (chats.isEmpty) {
      return const _DesktopEmptyCard(
        icon: Icons.photo_library_outlined,
        title: 'No media yet',
        subtitle: 'Image messages will become large desktop previews here.',
      );
    }

    return SizedBox(
      height: 174,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return _LargePreviewTile(
            icon: Icons.image_outlined,
            title: titleFor(chat),
            subtitle: TimeFormatter.formatChatTime(chat.lastMessageTime),
            accent: index.isEven
                ? DarkKickColors.neonPurple
                : const Color(0xFF7DD3FC),
            onTap: () => onOpen(chat),
          );
        },
      ),
    );
  }
}

class _FavoriteContactsGrid extends StatelessWidget {
  const _FavoriteContactsGrid({
    required this.chats,
    required this.titleFor,
    required this.onOpen,
  });

  final List<Chat> chats;
  final String Function(Chat chat) titleFor;
  final ValueChanged<Chat> onOpen;

  @override
  Widget build(BuildContext context) {
    if (chats.isEmpty) {
      return const _DesktopEmptyCard(
        icon: Icons.star_border_rounded,
        title: 'No favorites yet',
        subtitle: 'People you talk to most will stay close.',
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chats.map((chat) {
        final title = titleFor(chat);
        return InkWell(
          onTap: () => onOpen(chat),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 108,
            height: 116,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DarkKickColors.panel.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              children: [
                _DesktopAvatar(
                  title: title,
                  color: DarkKickColors.cardSoft,
                  isGroup: chat.isGroup,
                  isOfficial: SystemBot.isSystemChat(chat),
                  size: 42,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DarkKickColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RecentFilesStrip extends StatelessWidget {
  const _RecentFilesStrip({
    required this.chats,
    required this.titleFor,
    required this.onOpen,
  });

  final List<Chat> chats;
  final String Function(Chat chat) titleFor;
  final ValueChanged<Chat> onOpen;

  @override
  Widget build(BuildContext context) {
    if (chats.isEmpty) {
      return const _DesktopEmptyCard(
        icon: Icons.folder_outlined,
        title: 'No files yet',
        subtitle: 'Desktop-safe attachments will be collected here.',
      );
    }

    return Column(
      children: chats
          .map(
            (chat) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FilePreviewTile(
                icon: Icons.insert_drive_file_outlined,
                title: chat.lastMessage,
                subtitle: titleFor(chat),
                onTap: () => onOpen(chat),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CallStatusCard extends StatelessWidget {
  const _CallStatusCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _LargePreviewTile(
      icon: Icons.phone_disabled_outlined,
      title: 'No active calls',
      subtitle: DesktopPlatformService.unsupportedDesktopMessage,
      accent: DarkKickColors.pending,
      onTap: onTap,
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.chat,
    required this.title,
    required this.currentUserId,
    required this.tab,
    required this.onBackHome,
    required this.onTabSelected,
    required this.onRefresh,
    required this.onOpenNewChat,
  });

  final Chat chat;
  final String title;
  final String? currentUserId;
  final _ConversationTab tab;
  final VoidCallback onBackHome;
  final ValueChanged<_ConversationTab> onTabSelected;
  final VoidCallback onRefresh;
  final VoidCallback onOpenNewChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
      child: Column(
        children: [
          Row(
            children: [
              Tooltip(
                message: 'Home',
                child: IconButton(
                  onPressed: onBackHome,
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  color: DarkKickColors.textSecondary,
                  style: IconButton.styleFrom(
                    backgroundColor: DarkKickColors.panel.withValues(
                      alpha: 0.78,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: DarkKickColors.divider),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              _DesktopAvatar(
                title: title,
                color: DarkKickColors.cardSoft,
                isGroup: chat.isGroup,
                isOfficial: SystemBot.isSystemChat(chat),
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${chat.participants.length} participants - ${chat.unreadFor(currentUserId)} unread',
                      style: const TextStyle(
                        color: DarkKickColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onPressed: onRefresh,
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.add_comment_outlined,
                tooltip: 'New conversation',
                onPressed: onOpenNewChat,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _WorkspaceTabs(selected: tab, onSelected: onTabSelected),
        ],
      ),
    );
  }
}

class _WorkspaceTabs extends StatelessWidget {
  const _WorkspaceTabs({required this.selected, required this.onSelected});

  final _ConversationTab selected;
  final ValueChanged<_ConversationTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TabData(_ConversationTab.chat, Icons.chat_bubble_outline, 'Chat'),
      _TabData(_ConversationTab.media, Icons.photo_library_outlined, 'Media'),
      _TabData(_ConversationTab.files, Icons.folder_outlined, 'Files'),
      _TabData(_ConversationTab.calls, Icons.call_outlined, 'Calls'),
      _TabData(_ConversationTab.profile, Icons.person_outline, 'Profile'),
    ];

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DarkKickColors.divider),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = tab.tab == selected;
          return Expanded(
            child: Tooltip(
              message: tab.label,
              child: InkWell(
                onTap: () => onSelected(tab.tab),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? DarkKickColors.neonPurple.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab.icon,
                        size: 17,
                        color: isSelected
                            ? DarkKickColors.electricPurple
                            : DarkKickColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : DarkKickColors.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabData {
  const _TabData(this.tab, this.icon, this.label);

  final _ConversationTab tab;
  final IconData icon;
  final String label;
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        color: DarkKickColors.textSecondary,
        style: IconButton.styleFrom(
          fixedSize: const Size(42, 42),
          backgroundColor: DarkKickColors.panel.withValues(alpha: 0.78),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: DarkKickColors.divider),
          ),
        ),
      ),
    );
  }
}

class _InspectorResizeHandle extends StatelessWidget {
  const _InspectorResizeHandle({required this.onDelta});

  final ValueChanged<double> onDelta;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) => onDelta(details.delta.dx),
        child: SizedBox(
          width: 18,
          child: Center(
            child: Container(
              width: 3,
              height: 54,
              decoration: BoxDecoration(
                color: DarkKickColors.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatWorkspaceCard extends StatelessWidget {
  const _ChatWorkspaceCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DarkKickColors.deepBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: child,
      ),
    );
  }
}

class _WorkspaceInspector extends StatelessWidget {
  const _WorkspaceInspector({
    required this.chat,
    required this.title,
    required this.currentUserId,
    required this.onOpenFiles,
    required this.onUnsupported,
  });

  final Chat chat;
  final String title;
  final String? currentUserId;
  final VoidCallback onOpenFiles;
  final VoidCallback onUnsupported;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _InspectorPanel(
          title: 'Workspace',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _DesktopAvatar(
                    title: title,
                    color: DarkKickColors.cardSoft,
                    isGroup: chat.isGroup,
                    isOfficial: SystemBot.isSystemChat(chat),
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _InspectorMetric(
                icon: Icons.mark_chat_unread_outlined,
                label: 'Unread',
                value: '${chat.unreadFor(currentUserId)}',
              ),
              _InspectorMetric(
                icon: Icons.schedule_outlined,
                label: 'Updated',
                value: TimeFormatter.formatChatTime(chat.updatedAt),
              ),
              _InspectorMetric(
                icon: Icons.people_outline,
                label: 'People',
                value: '${chat.participants.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _InspectorPanel(
          title: 'Desktop Intake',
          child: Column(
            children: [
              _InspectorAction(
                icon: Icons.upload_file_outlined,
                title: 'Attachment flow',
                subtitle: 'Use the Chat input for safe Windows picking.',
                onTap: onOpenFiles,
              ),
              _InspectorAction(
                icon: Icons.mic_off_outlined,
                title: 'Voice recording',
                subtitle: DesktopPlatformService.unsupportedDesktopMessage,
                onTap: onUnsupported,
              ),
              _InspectorAction(
                icon: Icons.open_in_new_rounded,
                title: 'Detached window',
                subtitle: 'Multi-window shell hook.',
                onTap: onUnsupported,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InspectorPanel extends StatelessWidget {
  const _InspectorPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: DarkKickColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InspectorMetric extends StatelessWidget {
  const _InspectorMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(icon, color: DarkKickColors.electricPurple, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: DarkKickColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorAction extends StatelessWidget {
  const _InspectorAction({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: DarkKickColors.textSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: DarkKickColors.textTertiary,
                      fontSize: 11,
                      height: 1.25,
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

class _WorkspaceDeck extends StatelessWidget {
  const _WorkspaceDeck({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: const TextStyle(
              color: DarkKickColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisExtent: 176,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _LargePreviewTile extends StatelessWidget {
  const _LargePreviewTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DarkKickColors.card.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.32)),
              ),
              child: Icon(icon, color: accent, size: 23),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DarkKickColors.textSecondary,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilePreviewTile extends StatelessWidget {
  const _FilePreviewTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DarkKickColors.card.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF172033),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2F3E58)),
              ),
              child: Icon(icon, color: const Color(0xFF7DD3FC), size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title.trim().isEmpty ? 'Attachment' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DarkKickColors.textSecondary,
                      fontSize: 12,
                      height: 1.25,
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

class _ProfileIdentityTile extends StatelessWidget {
  const _ProfileIdentityTile({
    required this.title,
    required this.chat,
    required this.currentUserId,
  });

  final String title;
  final Chat chat;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DarkKickColors.card.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DesktopAvatar(
            title: title,
            color: DarkKickColors.cardSoft,
            isGroup: chat.isGroup,
            isOfficial: SystemBot.isSystemChat(chat),
            size: 54,
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unread: ${chat.unreadFor(currentUserId)}',
            style: const TextStyle(
              color: DarkKickColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopEmptyCard extends StatelessWidget {
  const _DesktopEmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 152),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DarkKickColors.electricPurple, size: 28),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: const TextStyle(
              color: DarkKickColors.textSecondary,
              height: 1.3,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            _TopBarButton(
              icon: Icons.arrow_forward_rounded,
              label: actionLabel!,
              onTap: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}
