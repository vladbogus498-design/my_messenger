import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/system_bot.dart';
import '../data/darkkick_stickers.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../providers/chats_provider.dart';
import '../services/chat_service.dart';
import '../services/desktop_platform_service.dart';
import '../theme/darkkick_colors.dart';
import '../utils/logger.dart';
import '../utils/time_formatter.dart';
import '../utils/user_formatters.dart';
import 'desktop_settings_screen.dart';
import 'image_viewer_screen.dart';
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

enum _DesktopSection { home, conversations, calls, contacts, files, settings }

enum _ConversationTab { chat, media, files, calls, profile }

class _DesktopStrings {
  const _DesktopStrings(this.code);

  final String code;

  static _DesktopStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (_values.containsKey(code)) return _DesktopStrings(code);
    return const _DesktopStrings('en');
  }

  String t(String key) => _values[code]?[key] ?? _values['en']![key] ?? key;

  static const _values = {
    'en': {
      'home': 'Home',
      'railChats': 'Chats',
      'conversations': 'Conversations',
      'calls': 'Calls',
      'contacts': 'Contacts',
      'files': 'Files',
      'railMedia': 'Media',
      'settings': 'Settings',
      'workspaceOffline': 'Workspace offline',
      'workspaceOfflineSubtitle':
          'DARKKICK could not load your desktop workspace.',
      'retry': 'Retry',
      'homeSubtitle': 'A people-centered communication workspace.',
      'new': 'New',
      'continueConversations': 'Continue Conversations',
      'noActiveConversations': 'No active conversations',
      'startPrivateWorkspace': 'Start a private workspace from DARKKICK.',
      'start': 'Start',
      'recentMedia': 'Recent Media',
      'activeCalls': 'Active Calls',
      'favoriteContacts': 'Favorite Contacts',
      'recentFiles': 'Recent Files',
      'desktopTitle': 'DARKKICK Desktop',
      'desktopSubtitle':
          'Open conversations as workspaces, not message queues.',
      'spaces': 'spaces',
      'unread': 'unread',
      'windowsMode': 'Windows mode',
      'searchWorkspace': 'Search workspace',
      'pickConversation': 'Pick a person or group to open a workspace.',
      'nothingMatched': 'Nothing matched',
      'nothingMatchedSubtitle': 'Try another name or start a new conversation.',
      'newConversation': 'New conversation',
      'chat': 'Chat',
      'media': 'Media',
      'profile': 'Profile',
      'mediaBoard': 'Media',
      'mediaBoardSubtitle':
          'Shared photos and stickers from this conversation.',
      'noMedia': 'No media yet',
      'noMediaSubtitle': 'Photos and stickers from this chat will appear here.',
      'filesSubtitle': 'Shared documents, archives and attachments.',
      'noFiles': 'No files yet',
      'noFilesSubtitle': 'Attachments from this conversation will appear here.',
      'callsSubtitle':
          'Desktop calling controls stay isolated from mobile plugins.',
      'notAvailableDesktop': 'Not available on desktop yet',
      'callHistory': 'Call history',
      'callHistorySubtitle': 'Desktop call records will live here.',
      'profileSubtitle': 'Workspace identity and participant details.',
      'officialSpace': 'Official space',
      'privateSpace': 'Private space',
      'participants': 'participants',
      'desktopBehavior': 'Desktop behavior and workspace safety.',
      'desktopModeTitle': 'Windows Desktop Mode',
      'desktopModeSubtitle':
          'DARKKICK is running the safe desktop platform path.',
      'snapshotsAvoided': 'Realtime snapshots avoided',
      'snapshotsAvoidedSubtitle':
          'Open chats use polling to protect Windows stability.',
      'bytesMedia': 'Bytes-based media picking',
      'bytesMediaSubtitle':
          'Photos are selected through a desktop-safe picker.',
      'voicePaused': 'Voice recording paused',
      'workspace': 'Workspace',
      'updated': 'Updated',
      'people': 'People',
      'desktopIntake': 'Desktop Intake',
      'attachmentFlow': 'Attachment flow',
      'attachmentFlowSubtitle': 'Use the Chat input for safe Windows picking.',
      'voiceRecording': 'Voice recording',
      'detachedWindow': 'Detached window',
      'detachedWindowSubtitle': 'Multi-window shell hook.',
      'attachment': 'Attachment',
      'imageUnavailable': 'Image unavailable',
      'stickerUnavailable': 'Sticker unavailable',
      'photo': 'Photo',
      'sticker': 'Sticker',
      'voice': 'Voice',
      'file': 'File',
      'text': 'Text',
      'noMessagesYet': 'No messages yet',
    },
    'ru': {
      'home': 'Главная',
      'railChats': 'Чаты',
      'conversations': 'Диалоги',
      'calls': 'Звонки',
      'contacts': 'Контакты',
      'files': 'Файлы',
      'railMedia': 'Медиа',
      'settings': 'Настройки',
      'workspaceOffline': 'Рабочая область недоступна',
      'workspaceOfflineSubtitle':
          'DARKKICK не смог загрузить desktop-рабочую область.',
      'retry': 'Повторить',
      'homeSubtitle': 'Коммуникационная рабочая область вокруг людей.',
      'new': 'Новый',
      'continueConversations': 'Продолжить диалоги',
      'noActiveConversations': 'Активных диалогов нет',
      'startPrivateWorkspace': 'Начни приватную рабочую область в DARKKICK.',
      'start': 'Начать',
      'recentMedia': 'Недавние медиа',
      'activeCalls': 'Активные звонки',
      'favoriteContacts': 'Избранные контакты',
      'recentFiles': 'Недавние файлы',
      'desktopTitle': 'DARKKICK Desktop',
      'desktopSubtitle':
          'Открывай диалоги как рабочие области, а не очередь сообщений.',
      'spaces': 'пространств',
      'unread': 'непрочитано',
      'windowsMode': 'Режим Windows',
      'searchWorkspace': 'Поиск',
      'pickConversation':
          'Выбери человека или группу, чтобы открыть workspace.',
      'nothingMatched': 'Ничего не найдено',
      'nothingMatchedSubtitle': 'Попробуй другое имя или начни новый диалог.',
      'newConversation': 'Новый диалог',
      'chat': 'Чат',
      'media': 'Медиа',
      'profile': 'Профиль',
      'mediaBoard': 'Медиа',
      'mediaBoardSubtitle': 'Фото и стикеры из этого диалога.',
      'noMedia': 'Медиа пока нет',
      'noMediaSubtitle': 'Фото и стикеры из чата появятся здесь.',
      'filesSubtitle': 'Общие документы, архивы и вложения.',
      'noFiles': 'Файлов пока нет',
      'noFilesSubtitle': 'Вложения из этого диалога появятся здесь.',
      'callsSubtitle': 'Desktop-звонки отделены от мобильных плагинов.',
      'notAvailableDesktop': 'Пока недоступно на desktop',
      'callHistory': 'История звонков',
      'callHistorySubtitle': 'Desktop-звонки будут отображаться здесь.',
      'profileSubtitle': 'Профиль и участники рабочей области.',
      'officialSpace': 'Официальное пространство',
      'privateSpace': 'Приватное пространство',
      'participants': 'участников',
      'desktopBehavior': 'Поведение и стабильность desktop-версии.',
      'desktopModeTitle': 'Режим Windows Desktop',
      'desktopModeSubtitle': 'DARKKICK использует безопасный desktop-путь.',
      'snapshotsAvoided': 'Realtime snapshots отключены',
      'snapshotsAvoidedSubtitle':
          'Открытые чаты обновляются polling-ом для стабильности Windows.',
      'bytesMedia': 'Выбор медиа через bytes',
      'bytesMediaSubtitle': 'Фото выбираются через desktop-safe picker.',
      'voicePaused': 'Запись голоса отключена',
      'workspace': 'Workspace',
      'updated': 'Обновлено',
      'people': 'Люди',
      'desktopIntake': 'Desktop-ввод',
      'attachmentFlow': 'Вложения',
      'attachmentFlowSubtitle': 'Используй кнопку вложений в Chat для Windows.',
      'voiceRecording': 'Запись голоса',
      'detachedWindow': 'Отдельное окно',
      'detachedWindowSubtitle': 'Заготовка для multi-window режима.',
      'attachment': 'Вложение',
      'imageUnavailable': 'Изображение недоступно',
      'stickerUnavailable': 'Стикер недоступен',
      'photo': 'Фото',
      'sticker': 'Стикер',
      'voice': 'Голос',
      'file': 'Файл',
      'text': 'Текст',
      'noMessagesYet': 'Сообщений пока нет',
    },
    'pl': {
      'home': 'Start',
      'railChats': 'Czaty',
      'conversations': 'Rozmowy',
      'calls': 'Połączenia',
      'contacts': 'Kontakty',
      'files': 'Pliki',
      'railMedia': 'Media',
      'settings': 'Ustawienia',
      'workspaceOffline': 'Obszar roboczy offline',
      'workspaceOfflineSubtitle':
          'DARKKICK nie mógł wczytać obszaru roboczego desktop.',
      'retry': 'Ponów',
      'homeSubtitle': 'Przestrzeń komunikacji skupiona na ludziach.',
      'new': 'Nowa',
      'continueConversations': 'Kontynuuj rozmowy',
      'noActiveConversations': 'Brak aktywnych rozmów',
      'startPrivateWorkspace': 'Rozpocznij prywatną przestrzeń w DARKKICK.',
      'start': 'Start',
      'recentMedia': 'Ostatnie media',
      'activeCalls': 'Aktywne połączenia',
      'favoriteContacts': 'Ulubione kontakty',
      'recentFiles': 'Ostatnie pliki',
      'desktopTitle': 'DARKKICK Desktop',
      'desktopSubtitle':
          'Otwieraj rozmowy jako obszary robocze, nie kolejki wiadomości.',
      'spaces': 'przestrzeni',
      'unread': 'nieprzeczytane',
      'windowsMode': 'Tryb Windows',
      'searchWorkspace': 'Szukaj',
      'pickConversation': 'Wybierz osobę lub grupę, aby otworzyć workspace.',
      'nothingMatched': 'Nic nie znaleziono',
      'nothingMatchedSubtitle':
          'Spróbuj innej nazwy albo zacznij nową rozmowę.',
      'newConversation': 'Nowa rozmowa',
      'chat': 'Czat',
      'media': 'Media',
      'profile': 'Profil',
      'mediaBoard': 'Media',
      'mediaBoardSubtitle': 'Zdjęcia i naklejki z tej rozmowy.',
      'noMedia': 'Brak mediów',
      'noMediaSubtitle': 'Zdjęcia i naklejki z czatu pojawią się tutaj.',
      'filesSubtitle': 'Wspólne dokumenty, archiwa i załączniki.',
      'noFiles': 'Brak plików',
      'noFilesSubtitle': 'Załączniki z tej rozmowy pojawią się tutaj.',
      'callsSubtitle':
          'Sterowanie połączeniami desktop jest oddzielone od pluginów mobilnych.',
      'notAvailableDesktop': 'Jeszcze niedostępne na desktopie',
      'callHistory': 'Historia połączeń',
      'callHistorySubtitle': 'Połączenia desktop pojawią się tutaj.',
      'profileSubtitle': 'Tożsamość workspace i uczestnicy.',
      'officialSpace': 'Oficjalna przestrzeń',
      'privateSpace': 'Prywatna przestrzeń',
      'participants': 'uczestników',
      'desktopBehavior': 'Zachowanie i stabilność wersji desktop.',
      'desktopModeTitle': 'Tryb Windows Desktop',
      'desktopModeSubtitle': 'DARKKICK używa bezpiecznej ścieżki desktop.',
      'snapshotsAvoided': 'Realtime snapshots wyłączone',
      'snapshotsAvoidedSubtitle':
          'Otwarte czaty używają polling dla stabilności Windows.',
      'bytesMedia': 'Wybór mediów przez bytes',
      'bytesMediaSubtitle': 'Zdjęcia są wybierane desktop-safe pickerem.',
      'voicePaused': 'Nagrywanie głosu wyłączone',
      'workspace': 'Workspace',
      'updated': 'Aktualizacja',
      'people': 'Osoby',
      'desktopIntake': 'Wejście desktop',
      'attachmentFlow': 'Załączniki',
      'attachmentFlowSubtitle': 'Użyj przycisku załącznika w Chat dla Windows.',
      'voiceRecording': 'Nagrywanie głosu',
      'detachedWindow': 'Osobne okno',
      'detachedWindowSubtitle': 'Punkt integracji dla multi-window.',
      'attachment': 'Załącznik',
      'imageUnavailable': 'Obraz niedostępny',
      'stickerUnavailable': 'Naklejka niedostępna',
      'photo': 'Zdjęcie',
      'sticker': 'Naklejka',
      'voice': 'Głos',
      'file': 'Plik',
      'text': 'Tekst',
      'noMessagesYet': 'Brak wiadomości',
    },
  };
}

String? _desktopImageUrlFor(Message message) {
  final imageUrl = message.imageUrl?.trim();
  if (imageUrl == null || imageUrl.isEmpty) return null;
  final uri = Uri.tryParse(imageUrl);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    appLogger.w('Desktop skipped unsupported image URL: $imageUrl');
    return null;
  }
  return imageUrl;
}

String? _desktopStickerValueFor(Message message) {
  if (message.type.toLowerCase().trim() != 'sticker') return null;
  final sticker = message.stickerId?.trim().isNotEmpty == true
      ? message.stickerId!.trim()
      : message.stickerUrl?.trim();
  if (sticker == null || sticker.isEmpty) return null;
  return sticker;
}

bool _desktopIsAttachment(Message message) {
  return _desktopImageUrlFor(message) != null ||
      _desktopStickerValueFor(message) != null ||
      (message.voiceUrl?.trim().isNotEmpty ?? false);
}

IconData _desktopAttachmentIcon(Message message) {
  if (_desktopImageUrlFor(message) != null) return Icons.image_outlined;
  if (_desktopStickerValueFor(message) != null) {
    return Icons.sticky_note_2_outlined;
  }
  if (message.voiceUrl?.trim().isNotEmpty ?? false) {
    return Icons.graphic_eq_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

String _desktopAttachmentTitle(Message message, _DesktopStrings strings) {
  if (_desktopImageUrlFor(message) != null) return strings.t('photo');
  if (_desktopStickerValueFor(message) != null) return strings.t('sticker');
  if (message.voiceUrl?.trim().isNotEmpty ?? false) return strings.t('voice');
  final text = message.text.trim();
  if (text.isNotEmpty) return text;
  return strings.t('attachment');
}

String _desktopFormattedTime(DateTime value) {
  try {
    return TimeFormatter.formatChatTime(value);
  } catch (error, stackTrace) {
    appLogger.e(
      'Desktop failed to format message time',
      error: error,
      stackTrace: stackTrace,
    );
    return '';
  }
}

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
      if (!mounted) return;
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleDesktopBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
              const SingleActivator(
                LogicalKeyboardKey.keyR,
                control: true,
              ): () =>
                  ref.invalidate(chatsProvider),
              const SingleActivator(LogicalKeyboardKey.escape):
                  _handleDesktopBack,
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
                      error: (error, stackTrace) {
                        appLogger.e(
                          'Desktop workspace failed to load chats',
                          error: error,
                          stackTrace: stackTrace,
                        );
                        return _buildErrorShell(error);
                      },
                    ),
                  ),
                ],
              ),
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
        _DesktopSection.contacts => _buildContactsHub(chats),
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
    final strings = _DesktopStrings.of(context);

    return ColoredBox(
      color: DarkKickColors.deepBackground,
      child: Center(
        child: _DesktopEmptyCard(
          icon: Icons.cloud_off_outlined,
          title: strings.t('workspaceOffline'),
          subtitle: strings.t('workspaceOfflineSubtitle'),
          actionLabel: strings.t('retry'),
          onAction: () => ref.invalidate(chatsProvider),
        ),
      ),
    );
  }

  Widget _buildHome(List<Chat> chats) {
    final strings = _DesktopStrings.of(context);
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
      title: strings.t('home'),
      subtitle: strings.t('homeSubtitle'),
      trailing: _TopBarButton(
        icon: Icons.add_comment_outlined,
        label: strings.t('new'),
        onTap: widget.onOpenNewChat,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1120;
          final content = [
            _buildWelcomeSurface(chats),
            const SizedBox(height: 28),
            _DashboardSection(
              title: strings.t('continueConversations'),
              actionIcon: Icons.arrow_forward_rounded,
              onAction: () => _selectSection(_DesktopSection.conversations),
              child: continued.isEmpty
                  ? _DesktopEmptyCard(
                      icon: Icons.mode_comment_outlined,
                      title: strings.t('noActiveConversations'),
                      subtitle: strings.t('startPrivateWorkspace'),
                      actionLabel: strings.t('start'),
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
              title: strings.t('recentMedia'),
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
              title: strings.t('activeCalls'),
              child: _CallStatusCard(onTap: _showDesktopUnavailable),
            ),
            const SizedBox(height: 22),
            _DashboardSection(
              title: strings.t('favoriteContacts'),
              child: _FavoriteContactsGrid(
                chats: favorites,
                titleFor: _titleFor,
                currentUserId: widget.currentUserId,
                onOpen: _openConversation,
              ),
            ),
            const SizedBox(height: 22),
            _DashboardSection(
              title: strings.t('recentFiles'),
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
    final strings = _DesktopStrings.of(context);
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
                  strings.t('desktopTitle'),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  strings.t('desktopSubtitle'),
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
                      label: '${chats.length} ${strings.t('spaces')}',
                    ),
                    _MetricPill(
                      icon: Icons.mark_chat_unread_outlined,
                      label: '$unread ${strings.t('unread')}',
                    ),
                    _MetricPill(
                      icon: Icons.desktop_windows_outlined,
                      label: strings.t('windowsMode'),
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
    final strings = _DesktopStrings.of(context);
    final filtered = _searchQuery.isEmpty
        ? chats
        : chats
              .where(
                (chat) => _titleFor(chat).toLowerCase().contains(_searchQuery),
              )
              .toList();

    return _DesktopPageScaffold(
      title: strings.t('conversations'),
      subtitle: strings.t('pickConversation'),
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
            label: strings.t('new'),
            onTap: widget.onOpenNewChat,
          ),
        ],
      ),
      child: filtered.isEmpty
          ? Center(
              child: _DesktopEmptyCard(
                icon: Icons.search_off_outlined,
                title: strings.t('nothingMatched'),
                subtitle: strings.t('nothingMatchedSubtitle'),
                actionLabel: strings.t('newConversation'),
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
          onBackHome: _closeConversation,
          onTabSelected: _selectWorkspaceTab,
          onRefresh: () => ref.invalidate(chatsProvider),
          onOpenNewChat: widget.onOpenNewChat,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
            child: Row(
              children: [
                Expanded(child: _buildSafeWorkspaceBody(chat, chats)),
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

  Widget _buildSafeWorkspaceBody(Chat chat, List<Chat> chats) {
    final strings = _DesktopStrings.of(context);

    return _DesktopTabGuard(
      tabLabel: _tabLabel(_conversationTab, strings),
      onRetry: () => setState(() {}),
      builder: (_) => _buildWorkspaceBody(chat, chats),
    );
  }

  Widget _buildWorkspaceBody(Chat chat, List<Chat> chats) {
    final strings = _DesktopStrings.of(context);

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
        _ConversationTab.media => _ConversationMediaBoard(
          key: ValueKey('media-${chat.id}'),
          chat: chat,
          title: _titleFor(chat),
        ),
        _ConversationTab.files => _ConversationFilesBoard(
          key: ValueKey('files-${chat.id}'),
          chat: chat,
          title: _titleFor(chat),
        ),
        _ConversationTab.calls => _WorkspaceDeck(
          key: ValueKey('calls-${chat.id}'),
          title: strings.t('calls'),
          subtitle: strings.t('callsSubtitle'),
          children: [
            _LargePreviewTile(
              icon: Icons.phone_disabled_outlined,
              title: strings.t('notAvailableDesktop'),
              subtitle: strings.t('notAvailableDesktop'),
              accent: DarkKickColors.pending,
              onTap: _showDesktopUnavailable,
            ),
            _LargePreviewTile(
              icon: Icons.history_toggle_off_outlined,
              title: strings.t('callHistory'),
              subtitle: strings.t('callHistorySubtitle'),
              accent: const Color(0xFF7DD3FC),
            ),
          ],
        ),
        _ConversationTab.profile => _WorkspaceDeck(
          key: ValueKey('profile-${chat.id}'),
          title: strings.t('profile'),
          subtitle: strings.t('profileSubtitle'),
          children: [
            _ProfileIdentityTile(
              title: _titleFor(chat),
              chat: chat,
              currentUserId: widget.currentUserId,
            ),
            _FilePreviewTile(
              icon: Icons.verified_user_outlined,
              title: SystemBot.isSystemChat(chat)
                  ? strings.t('officialSpace')
                  : strings.t('privateSpace'),
              subtitle:
                  '${chat.participants.length} ${strings.t('participants')}',
            ),
          ],
        ),
      },
    );
  }

  Widget _buildCallsHub(List<Chat> chats) {
    final strings = _DesktopStrings.of(context);

    return _DesktopPageScaffold(
      title: strings.t('calls'),
      subtitle: strings.t('callsSubtitle'),
      trailing: _TopBarButton(
        icon: Icons.phone_disabled_outlined,
        label: strings.t('notAvailableDesktop'),
        onTap: _showDesktopUnavailable,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(34, 0, 34, 34),
        children: [
          SizedBox(
            height: 430,
            child: _WorkspaceDeck(
              title: strings.t('activeCalls'),
              subtitle: strings.t('notAvailableDesktop'),
              children: [
                _LargePreviewTile(
                  icon: Icons.phone_disabled_outlined,
                  title: strings.t('notAvailableDesktop'),
                  subtitle: strings.t('notAvailableDesktop'),
                  accent: DarkKickColors.pending,
                  onTap: _showDesktopUnavailable,
                ),
                _LargePreviewTile(
                  icon: Icons.groups_2_outlined,
                  title: '${math.min(chats.length, 12)} ${strings.t('spaces')}',
                  subtitle: strings.t('callHistorySubtitle'),
                  accent: const Color(0xFF7DD3FC),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsHub(List<Chat> chats) {
    final strings = _DesktopStrings.of(context);
    final contacts = chats.where(_isDirectLikeChat).toList();

    return _DesktopPageScaffold(
      title: strings.t('contacts'),
      subtitle: strings.t('favoriteContacts'),
      trailing: _TopBarButton(
        icon: Icons.person_add_alt_1_outlined,
        label: strings.t('new'),
        onTap: widget.onOpenNewChat,
      ),
      child: contacts.isEmpty
          ? Center(
              child: _DesktopEmptyCard(
                icon: Icons.people_outline,
                title: strings.t('nothingMatched'),
                subtitle: strings.t('startPrivateWorkspace'),
                actionLabel: strings.t('start'),
                onAction: widget.onOpenNewChat,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(34, 0, 34, 34),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 270,
                mainAxisExtent: 190,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final chat = contacts[index];
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

  Widget _buildFilesHub(List<Chat> chats) {
    final strings = _DesktopStrings.of(context);
    final fileChats = chats
        .where((chat) => _looksLikeFileActivity(chat.lastMessageType))
        .take(12)
        .toList();

    return _DesktopPageScaffold(
      title: strings.t('files'),
      subtitle: strings.t('filesSubtitle'),
      trailing: _TopBarButton(
        icon: Icons.refresh_rounded,
        label: strings.t('retry'),
        onTap: () => ref.invalidate(chatsProvider),
      ),
      child: fileChats.isEmpty
          ? Center(
              child: _DesktopEmptyCard(
                icon: Icons.folder_open_outlined,
                title: strings.t('noFiles'),
                subtitle: strings.t('noFilesSubtitle'),
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
                  title: _messagePreview(chat, strings),
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
    return DesktopSettingsScreen(currentUserId: widget.currentUserId);
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
    if (!mounted) return;
    setState(() => _section = section);
  }

  void _selectWorkspaceTab(_ConversationTab tab) {
    if (!mounted) return;
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
    if (!mounted) return;
    if (chat.id.trim().isEmpty) {
      appLogger.w('Desktop ignored attempt to open an empty chat id');
      return;
    }
    setState(() {
      _activeChat = chat;
      _section = _DesktopSection.conversations;
      _conversationTab = _ConversationTab.chat;
    });
  }

  void _focusHomeSearch() {
    if (!mounted) return;
    setState(() => _section = _DesktopSection.home);
    _searchFocusNode.requestFocus();
  }

  void _goHome() {
    if (!mounted) return;
    setState(() => _section = _DesktopSection.home);
  }

  void _closeConversation() {
    if (!mounted) return;
    setState(() {
      _activeChat = null;
      _section = _DesktopSection.conversations;
      _conversationTab = _ConversationTab.chat;
    });
  }

  void _handleDesktopBack() {
    if (!mounted) return;
    if (_section == _DesktopSection.conversations && _activeChat != null) {
      _closeConversation();
      return;
    }
    if (_section != _DesktopSection.home) {
      _goHome();
    }
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_DesktopStrings.of(context).t('notAvailableDesktop')),
      ),
    );
  }

  String _tabLabel(_ConversationTab tab, _DesktopStrings strings) {
    return switch (tab) {
      _ConversationTab.chat => strings.t('chat'),
      _ConversationTab.media => strings.t('media'),
      _ConversationTab.files => strings.t('files'),
      _ConversationTab.calls => strings.t('calls'),
      _ConversationTab.profile => strings.t('profile'),
    };
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

  String _messagePreview(Chat chat, _DesktopStrings strings) {
    final text = chat.lastMessage.trim();
    if (text.isNotEmpty) return text;

    return switch (chat.lastMessageType.toLowerCase()) {
      'image' || 'photo' => strings.t('photo'),
      'sticker' => strings.t('sticker'),
      'voice' || 'audio' => strings.t('voice'),
      'file' || 'document' => strings.t('file'),
      _ => strings.t('noMessagesYet'),
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
    final strings = _DesktopStrings.of(context);
    final items = [
      _RailItemData(
        _DesktopSection.conversations,
        Icons.chat_bubble_outline,
        strings.t('railChats'),
      ),
      _RailItemData(
        _DesktopSection.calls,
        Icons.call_outlined,
        strings.t('calls'),
      ),
      _RailItemData(
        _DesktopSection.contacts,
        Icons.people_outline,
        strings.t('contacts'),
      ),
      _RailItemData(
        _DesktopSection.files,
        Icons.photo_library_outlined,
        strings.t('railMedia'),
      ),
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
            const SizedBox(height: 28),
            _RailItem(
              item: _RailItemData(
                _DesktopSection.settings,
                Icons.settings_outlined,
                strings.t('settings'),
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
    final strings = _DesktopStrings.of(context);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: DarkKickColors.textPrimary, fontSize: 14),
      cursorColor: DarkKickColors.neonPurple,
      decoration: InputDecoration(
        hintText: strings.t('searchWorkspace'),
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
    final strings = _DesktopStrings.of(context);
    final unread = chat.unreadFor(currentUserId);

    return Tooltip(
      message: title,
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
                  _DesktopChatAvatar(
                    chat: chat,
                    title: title,
                    currentUserId: currentUserId,
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
                _previewText(chat, strings),
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
                    _desktopFormattedTime(chat.lastMessageTime),
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

  String _previewText(Chat chat, _DesktopStrings strings) {
    final text = chat.lastMessage.trim();
    return text.isEmpty ? strings.t('noMessagesYet') : text;
  }
}

class _DesktopAvatar extends StatelessWidget {
  const _DesktopAvatar({
    required this.title,
    required this.color,
    required this.isGroup,
    required this.isOfficial,
    required this.size,
    this.photoUrl,
  });

  final String title;
  final Color color;
  final bool isGroup;
  final bool isOfficial;
  final double size;
  final String? photoUrl;

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
            : photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _DesktopAvatarFallback(
                  initial: initial,
                  isGroup: isGroup,
                  size: size,
                ),
              )
            : _DesktopAvatarFallback(
                initial: initial,
                isGroup: isGroup,
                size: size,
              ),
      ),
    );
  }
}

class _DesktopAvatarFallback extends StatelessWidget {
  const _DesktopAvatarFallback({
    required this.initial,
    required this.isGroup,
    required this.size,
  });

  final String initial;
  final bool isGroup;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isGroup) {
      return Icon(
        Icons.groups_2_outlined,
        color: Colors.white.withValues(alpha: 0.92),
        size: size * 0.42,
      );
    }

    return Text(
      initial,
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.36,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DesktopChatAvatar extends StatelessWidget {
  const _DesktopChatAvatar({
    required this.chat,
    required this.title,
    required this.currentUserId,
    required this.size,
  });

  final Chat chat;
  final String title;
  final String? currentUserId;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (SystemBot.isSystemChat(chat) || chat.isGroup) {
      return _DesktopAvatar(
        title: title,
        color: DarkKickColors.cardSoft,
        isGroup: chat.isGroup,
        isOfficial: SystemBot.isSystemChat(chat),
        size: size,
      );
    }

    final peerId = chat.otherParticipantId(currentUserId);
    if (peerId == null || peerId.isEmpty) {
      return _DesktopAvatar(
        title: title,
        color: DarkKickColors.cardSoft,
        isGroup: chat.isGroup,
        isOfficial: false,
        size: size,
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('publicProfiles')
          .doc(peerId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          appLogger.e(
            'Desktop avatar failed to load public profile $peerId',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
        }

        String? photoUrl;
        DateTime? avatarUpdatedAt;
        try {
          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          photoUrl = UserFormatters.readPhotoUrl(data);
          avatarUpdatedAt = UserFormatters.readDate(data['avatarUpdatedAt']);
        } catch (error, stackTrace) {
          appLogger.e(
            'Desktop avatar failed to parse public profile $peerId',
            error: error,
            stackTrace: stackTrace,
          );
        }

        return _DesktopAvatar(
          title: title,
          color: DarkKickColors.cardSoft,
          isGroup: false,
          isOfficial: false,
          size: size,
          photoUrl: UserFormatters.versionedImageUrl(photoUrl, avatarUpdatedAt),
        );
      },
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final normalized = type.trim().isEmpty ? 'text' : type.trim();
    final strings = _DesktopStrings.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: DarkKickColors.deepBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: DarkKickColors.divider),
      ),
      child: Text(
        _typeLabel(normalized, strings),
        style: const TextStyle(
          color: DarkKickColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _typeLabel(String type, _DesktopStrings strings) {
    return switch (type.toLowerCase()) {
      'image' || 'photo' => strings.t('photo'),
      'sticker' => strings.t('sticker'),
      'voice' || 'audio' => strings.t('voice'),
      'file' || 'document' => strings.t('file'),
      _ => strings.t('text'),
    };
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
    final strings = _DesktopStrings.of(context);

    if (chats.isEmpty) {
      return _DesktopEmptyCard(
        icon: Icons.photo_library_outlined,
        title: strings.t('noMedia'),
        subtitle: strings.t('noMediaSubtitle'),
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
            subtitle: _desktopFormattedTime(chat.lastMessageTime),
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
    required this.currentUserId,
    required this.onOpen,
  });

  final List<Chat> chats;
  final String Function(Chat chat) titleFor;
  final String? currentUserId;
  final ValueChanged<Chat> onOpen;

  @override
  Widget build(BuildContext context) {
    final strings = _DesktopStrings.of(context);

    if (chats.isEmpty) {
      return _DesktopEmptyCard(
        icon: Icons.star_border_rounded,
        title: strings.t('favoriteContacts'),
        subtitle: strings.t('noActiveConversations'),
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
                _DesktopChatAvatar(
                  chat: chat,
                  title: title,
                  currentUserId: currentUserId,
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
    final strings = _DesktopStrings.of(context);

    if (chats.isEmpty) {
      return _DesktopEmptyCard(
        icon: Icons.folder_outlined,
        title: strings.t('noFiles'),
        subtitle: strings.t('noFilesSubtitle'),
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
    final strings = _DesktopStrings.of(context);

    return _LargePreviewTile(
      icon: Icons.phone_disabled_outlined,
      title: strings.t('activeCalls'),
      subtitle: strings.t('notAvailableDesktop'),
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
    final strings = _DesktopStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
      child: Column(
        children: [
          Row(
            children: [
              Tooltip(
                message: strings.t('conversations'),
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
              _DesktopChatAvatar(
                chat: chat,
                title: title,
                currentUserId: currentUserId,
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
                tooltip: strings.t('newConversation'),
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
    final strings = _DesktopStrings.of(context);
    final tabs = [
      _TabData(
        _ConversationTab.chat,
        Icons.chat_bubble_outline,
        strings.t('chat'),
      ),
      _TabData(
        _ConversationTab.media,
        Icons.photo_library_outlined,
        strings.t('media'),
      ),
      _TabData(
        _ConversationTab.files,
        Icons.folder_outlined,
        strings.t('files'),
      ),
      _TabData(_ConversationTab.calls, Icons.call_outlined, strings.t('calls')),
      _TabData(
        _ConversationTab.profile,
        Icons.person_outline,
        strings.t('profile'),
      ),
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

class _DesktopTabGuard extends StatelessWidget {
  const _DesktopTabGuard({
    required this.tabLabel,
    required this.builder,
    required this.onRetry,
  });

  final String tabLabel;
  final WidgetBuilder builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = _DesktopStrings.of(context);

    try {
      return builder(context);
    } catch (error, stackTrace) {
      appLogger.e(
        'Desktop tab "$tabLabel" failed to build',
        error: error,
        stackTrace: stackTrace,
      );

      return _WorkspaceDataDeck(
        title: tabLabel,
        subtitle: strings.t('workspaceOfflineSubtitle'),
        child: Center(
          child: _DesktopEmptyCard(
            icon: Icons.warning_amber_rounded,
            title: strings.t('workspaceOffline'),
            subtitle: strings.t('workspaceOfflineSubtitle'),
            actionLabel: strings.t('retry'),
            onAction: onRetry,
          ),
        ),
      );
    }
  }
}

class _ConversationMediaBoard extends StatefulWidget {
  const _ConversationMediaBoard({
    super.key,
    required this.chat,
    required this.title,
  });

  final Chat chat;
  final String title;

  @override
  State<_ConversationMediaBoard> createState() =>
      _ConversationMediaBoardState();
}

class _ConversationMediaBoardState extends State<_ConversationMediaBoard> {
  late Future<List<Message>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _loadMessages();
  }

  @override
  void didUpdateWidget(covariant _ConversationMediaBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chat.id != widget.chat.id) {
      _messagesFuture = _loadMessages();
    }
  }

  Future<List<Message>> _loadMessages() async {
    final chatId = widget.chat.id.trim();
    if (chatId.isEmpty) return const <Message>[];

    try {
      return await ChatService.getChatMessages(chatId);
    } catch (error, stackTrace) {
      appLogger.e(
        'Desktop media tab failed to load messages for chat $chatId',
        error: error,
        stackTrace: stackTrace,
      );
      return const <Message>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = _DesktopStrings.of(context);

    return _WorkspaceDataDeck(
      title: strings.t('mediaBoard'),
      subtitle: strings.t('mediaBoardSubtitle'),
      child: FutureBuilder<List<Message>>(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: DarkKickColors.neonPurple,
              ),
            );
          }

          if (snapshot.hasError) {
            appLogger.e(
              'Desktop media tab FutureBuilder error for chat ${widget.chat.id}',
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
            );
          }

          final List<Message> media;
          try {
            final messages = snapshot.data ?? const <Message>[];
            media =
                messages
                    .where(
                      (message) =>
                          _desktopImageUrlFor(message) != null ||
                          _desktopStickerValueFor(message) != null,
                    )
                    .toList()
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          } catch (error, stackTrace) {
            appLogger.e(
              'Desktop media tab failed to prepare items for chat ${widget.chat.id}',
              error: error,
              stackTrace: stackTrace,
            );
            return Center(
              child: _DesktopEmptyCard(
                icon: Icons.photo_library_outlined,
                title: strings.t('noMedia'),
                subtitle: strings.t('noMediaSubtitle'),
              ),
            );
          }

          if (media.isEmpty) {
            return Center(
              child: _DesktopEmptyCard(
                icon: Icons.photo_library_outlined,
                title: strings.t('noMedia'),
                subtitle: strings.t('noMediaSubtitle'),
              ),
            );
          }

          final imageItems = media
              .map((message) {
                final imageUrl = _desktopImageUrlFor(message);
                if (imageUrl == null) return null;
                return ChatImageItem(messageId: message.id, imageUrl: imageUrl);
              })
              .whereType<ChatImageItem>()
              .toList();

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisExtent: 210,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: media.length,
            itemBuilder: (context, index) {
              final message = media[index];
              final imageUrl = _desktopImageUrlFor(message);
              if (imageUrl != null) {
                return _DesktopMediaImageTile(
                  message: message,
                  imageUrl: imageUrl,
                  onTap: () {
                    if (!mounted || imageItems.isEmpty) return;
                    final initialIndex = imageItems.indexWhere(
                      (item) => item.messageId == message.id,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ImageViewerScreen(
                          images: imageItems,
                          initialIndex: initialIndex < 0 ? 0 : initialIndex,
                        ),
                      ),
                    );
                  },
                );
              }

              return _DesktopStickerMediaTile(message: message);
            },
          );
        },
      ),
    );
  }
}

class _ConversationFilesBoard extends StatefulWidget {
  const _ConversationFilesBoard({
    super.key,
    required this.chat,
    required this.title,
  });

  final Chat chat;
  final String title;

  @override
  State<_ConversationFilesBoard> createState() =>
      _ConversationFilesBoardState();
}

class _ConversationFilesBoardState extends State<_ConversationFilesBoard> {
  late Future<List<Message>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _loadMessages();
  }

  @override
  void didUpdateWidget(covariant _ConversationFilesBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chat.id != widget.chat.id) {
      _messagesFuture = _loadMessages();
    }
  }

  Future<List<Message>> _loadMessages() async {
    final chatId = widget.chat.id.trim();
    if (chatId.isEmpty) return const <Message>[];

    try {
      return await ChatService.getChatMessages(chatId);
    } catch (error, stackTrace) {
      appLogger.e(
        'Desktop files tab failed to load messages for chat $chatId',
        error: error,
        stackTrace: stackTrace,
      );
      return const <Message>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = _DesktopStrings.of(context);

    return _WorkspaceDataDeck(
      title: strings.t('files'),
      subtitle: strings.t('filesSubtitle'),
      child: FutureBuilder<List<Message>>(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: DarkKickColors.neonPurple,
              ),
            );
          }

          if (snapshot.hasError) {
            appLogger.e(
              'Desktop files tab FutureBuilder error for chat ${widget.chat.id}',
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
            );
          }

          final List<Message> attachments;
          try {
            attachments =
                (snapshot.data ?? const <Message>[])
                    .where(_desktopIsAttachment)
                    .toList()
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          } catch (error, stackTrace) {
            appLogger.e(
              'Desktop files tab failed to prepare items for chat ${widget.chat.id}',
              error: error,
              stackTrace: stackTrace,
            );
            return Center(
              child: _DesktopEmptyCard(
                icon: Icons.folder_open_outlined,
                title: strings.t('noFiles'),
                subtitle: strings.t('noFilesSubtitle'),
              ),
            );
          }

          if (attachments.isEmpty) {
            return Center(
              child: _DesktopEmptyCard(
                icon: Icons.folder_open_outlined,
                title: strings.t('noFiles'),
                subtitle: strings.t('noFilesSubtitle'),
              ),
            );
          }

          return ListView.separated(
            itemCount: attachments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final message = attachments[index];
              return _FilePreviewTile(
                icon: _desktopAttachmentIcon(message),
                title: _desktopAttachmentTitle(message, strings),
                subtitle: _desktopFormattedTime(message.timestamp),
              );
            },
          );
        },
      ),
    );
  }
}

class _WorkspaceDataDeck extends StatelessWidget {
  const _WorkspaceDataDeck({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DesktopMediaImageTile extends StatelessWidget {
  const _DesktopMediaImageTile({
    required this.message,
    required this.imageUrl,
    required this.onTap,
  });

  final Message message;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = _DesktopStrings.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'chat-image-${message.id}',
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ColoredBox(
                  color: DarkKickColors.panel,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: DarkKickColors.neonPurple,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => ColoredBox(
                  color: DarkKickColors.card,
                  child: Center(
                    child: Text(
                      strings.t('imageUnavailable'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: DarkKickColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: _MediaLabel(
                icon: Icons.image_outlined,
                label: _desktopFormattedTime(message.timestamp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopStickerMediaTile extends StatelessWidget {
  const _DesktopStickerMediaTile({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final strings = _DesktopStrings.of(context);
    final sticker = _desktopStickerValueFor(message) ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarkKickColors.card.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: _DesktopStickerImage(
                sticker: sticker,
                missingLabel: strings.t('stickerUnavailable'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _MediaLabel(
            icon: Icons.sticky_note_2_outlined,
            label: _desktopFormattedTime(message.timestamp),
          ),
        ],
      ),
    );
  }
}

class _DesktopStickerImage extends StatelessWidget {
  const _DesktopStickerImage({
    required this.sticker,
    required this.missingLabel,
  });

  final String sticker;
  final String missingLabel;

  @override
  Widget build(BuildContext context) {
    final trimmed = sticker.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return CachedNetworkImage(
        imageUrl: trimmed,
        width: 148,
        height: 148,
        fit: BoxFit.contain,
        placeholder: (context, url) => const SizedBox(
          width: 148,
          height: 148,
          child: Center(
            child: CircularProgressIndicator(
              color: DarkKickColors.neonPurple,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _MissingMediaLabel(label: missingLabel),
      );
    }

    final assetPath =
        DarkkickStickers.assetFor(trimmed) ??
        (trimmed.startsWith('assets/') ? trimmed : null);
    if (assetPath == null) return _MissingMediaLabel(label: missingLabel);

    return Image.asset(
      assetPath,
      width: 148,
      height: 148,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => _MissingMediaLabel(label: missingLabel),
    );
  }
}

class _MissingMediaLabel extends StatelessWidget {
  const _MissingMediaLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(color: DarkKickColors.textSecondary, fontSize: 12),
    );
  }
}

class _MediaLabel extends StatelessWidget {
  const _MediaLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    final strings = _DesktopStrings.of(context);

    return ListView(
      children: [
        _InspectorPanel(
          title: strings.t('workspace'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _DesktopChatAvatar(
                    chat: chat,
                    title: title,
                    currentUserId: currentUserId,
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
                label: strings.t('unread'),
                value: '${chat.unreadFor(currentUserId)}',
              ),
              _InspectorMetric(
                icon: Icons.schedule_outlined,
                label: strings.t('updated'),
                value: _desktopFormattedTime(chat.updatedAt),
              ),
              _InspectorMetric(
                icon: Icons.people_outline,
                label: strings.t('people'),
                value: '${chat.participants.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _InspectorPanel(
          title: strings.t('desktopIntake'),
          child: Column(
            children: [
              _InspectorAction(
                icon: Icons.upload_file_outlined,
                title: strings.t('attachmentFlow'),
                subtitle: strings.t('attachmentFlowSubtitle'),
                onTap: onOpenFiles,
              ),
              _InspectorAction(
                icon: Icons.mic_off_outlined,
                title: strings.t('voiceRecording'),
                subtitle: strings.t('notAvailableDesktop'),
                onTap: onUnsupported,
              ),
              _InspectorAction(
                icon: Icons.open_in_new_rounded,
                title: strings.t('detachedWindow'),
                subtitle: strings.t('detachedWindowSubtitle'),
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
    final strings = _DesktopStrings.of(context);

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
                    title.trim().isEmpty ? strings.t('attachment') : title,
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
    final strings = _DesktopStrings.of(context);

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
          _DesktopChatAvatar(
            chat: chat,
            title: title,
            currentUserId: currentUserId,
            size: 54,
          ),
          const SizedBox(height: 28),
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
            '${strings.t('unread')}: ${chat.unreadFor(currentUserId)}',
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
