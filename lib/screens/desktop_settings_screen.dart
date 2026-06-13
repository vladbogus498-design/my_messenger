import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/selected_media.dart';
import '../models/user_model.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../theme/darkkick_colors.dart';
import '../utils/logger.dart';
import '../utils/user_formatters.dart';

enum _SettingsCategory {
  account,
  appearance,
  chats,
  notifications,
  privacy,
  storage,
  calls,
  security,
  hotkeys,
  language,
  about,
}

class DesktopSettingsScreen extends ConsumerStatefulWidget {
  const DesktopSettingsScreen({super.key, required this.currentUserId});

  final String? currentUserId;

  @override
  ConsumerState<DesktopSettingsScreen> createState() =>
      _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState extends ConsumerState<DesktopSettingsScreen> {
  static const _accentPref = 'desktop_settings_accent';
  static const _fontScalePref = 'desktop_settings_font_scale';
  static const _compactPref = 'desktop_settings_compact';
  static const _enterToSendPref = 'desktop_settings_enter_to_send';
  static const _autoDownloadPref = 'desktop_settings_auto_download';
  static const _stickerPreviewPref = 'desktop_settings_sticker_preview';
  static const _linkPreviewPref = 'desktop_settings_link_preview';
  static const _desktopNotificationsPref =
      'desktop_settings_desktop_notifications';
  static const _soundPref = 'desktop_settings_sound';
  static const _mentionsPref = 'desktop_settings_mentions';
  static const _dndPref = 'desktop_settings_dnd';
  static const _onlineVisibilityPref = 'desktop_settings_online_visibility';
  static const _readReceiptsPref = 'desktop_settings_read_receipts';

  _SettingsCategory _category = _SettingsCategory.account;
  Future<UserModel?>? _profileFuture;
  bool _busy = false;
  bool _prefsLoaded = false;
  bool _compactMode = false;
  bool _enterToSend = true;
  bool _autoDownload = true;
  bool _stickerPreview = true;
  bool _linkPreview = true;
  bool _desktopNotifications = true;
  bool _notificationSound = true;
  bool _mentionsOnly = false;
  bool _dndMode = false;
  bool _onlineVisibility = true;
  bool _readReceipts = true;
  double _fontScale = 1;
  String _accent = 'purple';
  String _cacheSize = '';
  String _downloadsFolder = '';

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    unawaited(_loadPreferences());
  }

  @override
  void didUpdateWidget(covariant DesktopSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUserId != widget.currentUserId) {
      _profileFuture = _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = _DesktopSettingsStrings.of(context);

    return FutureBuilder<UserModel?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          appLogger.e(
            'Desktop settings profile future failed',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
        }

        final profile = snapshot.data;
        final authUser = FirebaseAuth.instance.currentUser;

        return LayoutBuilder(
          builder: (context, constraints) {
            final navWidth = constraints.maxWidth < 980 ? 280.0 : 328.0;

            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DarkKickColors.deepBackground,
                    Color(0xFF080611),
                    Color(0xFF030207),
                  ],
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: navWidth,
                    child: _SettingsNavigation(
                      selected: _category,
                      profile: profile,
                      authUser: authUser,
                      onSelected: _selectCategory,
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: DarkKickColors.divider,
                  ),
                  Expanded(
                    child: _SettingsMainPane(
                      title: strings.titleFor(_category),
                      child: _buildCategory(strings, profile, authUser),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategory(
    _DesktopSettingsStrings strings,
    UserModel? profile,
    User? authUser,
  ) {
    try {
      return switch (_category) {
        _SettingsCategory.account => _buildAccount(strings, profile, authUser),
        _SettingsCategory.appearance => _buildAppearance(strings),
        _SettingsCategory.chats => _buildChats(strings),
        _SettingsCategory.notifications => _buildNotifications(strings),
        _SettingsCategory.privacy => _buildPrivacy(strings),
        _SettingsCategory.storage => _buildStorage(strings),
        _SettingsCategory.calls => _buildCalls(strings),
        _SettingsCategory.security => _buildSecurity(strings),
        _SettingsCategory.hotkeys => _buildHotkeys(strings),
        _SettingsCategory.language => _buildLanguage(strings),
        _SettingsCategory.about => _buildAbout(strings),
      };
    } catch (error, stackTrace) {
      appLogger.e(
        'Desktop settings category failed: $_category',
        error: error,
        stackTrace: stackTrace,
      );
      return _SettingsPlaceholder(
        icon: Icons.warning_amber_rounded,
        title: strings.t('settingsUnavailable'),
        subtitle: strings.t('settingsUnavailableSubtitle'),
      );
    }
  }

  Widget _buildAccount(
    _DesktopSettingsStrings strings,
    UserModel? profile,
    User? authUser,
  ) {
    final displayName = _displayName(profile, authUser, strings);
    final username = _username(profile, authUser);
    final email = _email(profile, authUser, strings);
    final bio = _safe(profile?.bio, strings.t('notSet'));
    final photoUrl = UserFormatters.versionedImageUrl(
      profile?.photoURL ?? authUser?.photoURL,
      profile?.avatarUpdatedAt,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
      children: [
        _AccountHero(
          displayName: displayName,
          username: username,
          email: email,
          photoUrl: photoUrl,
          busy: _busy,
          onChangeAvatar: _changeAvatar,
          onEditProfile: () => _editText(
            title: strings.t('username'),
            initialValue: username.replaceFirst('@', ''),
            onSave: (value) => UserService.updateUserData(tag: value),
          ),
        ),
        const SizedBox(height: 16),
        _SettingsSection(
          children: [
            _SettingsActionRow(
              title: strings.t('username'),
              value: username,
              actionLabel: strings.t('change'),
              onPressed: () => _editText(
                title: strings.t('username'),
                initialValue: username.replaceFirst('@', ''),
                onSave: (value) => UserService.updateUserData(tag: value),
              ),
            ),
            _SettingsActionRow(
              title: strings.t('email'),
              value: email,
              actionLabel: strings.t('change'),
              onPressed: () => _unsupported(strings),
            ),
            _SettingsActionRow(
              title: strings.t('bio'),
              value: bio,
              actionLabel: strings.t('change'),
              onPressed: () => _editText(
                title: strings.t('bio'),
                initialValue: profile?.bio ?? '',
                maxLines: 4,
                onSave: (value) => UserService.updateUserData(bio: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsSection(
          title: strings.t('accountManagement'),
          children: [
            _SettingsNavigationRow(
              title: strings.t('activeSessions'),
              subtitle: strings.t('activeSessionsSubtitle'),
              onTap: () => _unsupported(strings),
            ),
            _SettingsNavigationRow(
              title: strings.t('twoFactor'),
              subtitle: strings.t('twoFactorSubtitle'),
              trailing: Text(
                strings.t('disabled'),
                style: const TextStyle(
                  color: Color(0xFFFF8A8A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => _unsupported(strings),
            ),
            _SettingsNavigationRow(
              title: strings.t('exportData'),
              subtitle: strings.t('exportDataSubtitle'),
              onTap: () => _unsupported(strings),
            ),
            _SettingsNavigationRow(
              title: strings.t('deleteAccount'),
              subtitle: strings.t('deleteAccountSubtitle'),
              danger: true,
              onTap: () => _confirmDeleteAccount(strings),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppearance(_DesktopSettingsStrings strings) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode != ThemeMode.light;

    return _SettingsListPage(
      children: [
        _SettingsSection(
          children: [
            _SettingsSwitchRow(
              title: strings.t('darkTheme'),
              subtitle: strings.t('darkThemeSubtitle'),
              value: isDark,
              onChanged: (value) => _runAction(
                () => ref
                    .read(themeNotifierProvider.notifier)
                    .setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
                strings,
              ),
            ),
            _AccentColorRow(
              title: strings.t('accentColor'),
              value: _accent,
              onChanged: (value) => _setStringPref(_accentPref, value, () {
                _accent = value;
              }),
            ),
            _SettingsSliderRow(
              title: strings.t('fontScale'),
              value: _fontScale,
              min: 0.9,
              max: 1.2,
              divisions: 6,
              onChanged: (value) => _setDoublePref(_fontScalePref, value, () {
                _fontScale = value;
              }),
            ),
            _SettingsSwitchRow(
              title: strings.t('compactMode'),
              subtitle: strings.t('compactModeSubtitle'),
              value: _compactMode,
              onChanged: (value) => _setBoolPref(_compactPref, value, () {
                _compactMode = value;
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChats(_DesktopSettingsStrings strings) {
    return _SettingsListPage(
      children: [
        _SettingsSection(
          children: [
            _SettingsSwitchRow(
              title: strings.t('enterToSend'),
              subtitle: strings.t('enterToSendSubtitle'),
              value: _enterToSend,
              onChanged: (value) => _setBoolPref(_enterToSendPref, value, () {
                _enterToSend = value;
              }),
            ),
            _SettingsSwitchRow(
              title: strings.t('mediaAutoDownload'),
              subtitle: strings.t('mediaAutoDownloadSubtitle'),
              value: _autoDownload,
              onChanged: (value) => _setBoolPref(_autoDownloadPref, value, () {
                _autoDownload = value;
              }),
            ),
            _SettingsSwitchRow(
              title: strings.t('stickerSettings'),
              subtitle: strings.t('stickerSettingsSubtitle'),
              value: _stickerPreview,
              onChanged: (value) =>
                  _setBoolPref(_stickerPreviewPref, value, () {
                    _stickerPreview = value;
                  }),
            ),
            _SettingsSwitchRow(
              title: strings.t('previewSettings'),
              subtitle: strings.t('previewSettingsSubtitle'),
              value: _linkPreview,
              onChanged: (value) => _setBoolPref(_linkPreviewPref, value, () {
                _linkPreview = value;
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotifications(_DesktopSettingsStrings strings) {
    return _SettingsListPage(
      children: [
        _SettingsSection(
          children: [
            _SettingsSwitchRow(
              title: strings.t('desktopNotifications'),
              subtitle: strings.t('desktopNotificationsSubtitle'),
              value: _desktopNotifications,
              onChanged: (value) => _setBoolPref(
                _desktopNotificationsPref,
                value,
                () => _desktopNotifications = value,
              ),
            ),
            _SettingsSwitchRow(
              title: strings.t('sound'),
              subtitle: strings.t('soundSubtitle'),
              value: _notificationSound,
              onChanged: (value) => _setBoolPref(_soundPref, value, () {
                _notificationSound = value;
              }),
            ),
            _SettingsSwitchRow(
              title: strings.t('mentions'),
              subtitle: strings.t('mentionsSubtitle'),
              value: _mentionsOnly,
              onChanged: (value) => _setBoolPref(_mentionsPref, value, () {
                _mentionsOnly = value;
              }),
            ),
            _SettingsSwitchRow(
              title: strings.t('dndMode'),
              subtitle: strings.t('dndModeSubtitle'),
              value: _dndMode,
              onChanged: (value) => _setBoolPref(_dndPref, value, () {
                _dndMode = value;
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrivacy(_DesktopSettingsStrings strings) {
    return _SettingsListPage(
      children: [
        _SettingsSection(
          children: [
            _SettingsSwitchRow(
              title: strings.t('onlineVisibility'),
              subtitle: strings.t('onlineVisibilitySubtitle'),
              value: _onlineVisibility,
              onChanged: (value) =>
                  _setBoolPref(_onlineVisibilityPref, value, () {
                    _onlineVisibility = value;
                  }),
            ),
            _SettingsSwitchRow(
              title: strings.t('readReceipts'),
              subtitle: strings.t('readReceiptsSubtitle'),
              value: _readReceipts,
              onChanged: (value) => _setBoolPref(_readReceiptsPref, value, () {
                _readReceipts = value;
              }),
            ),
            _SettingsNavigationRow(
              title: strings.t('blockedContacts'),
              subtitle: strings.t('blockedContactsSubtitle'),
              onTap: () => _unsupported(strings),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStorage(_DesktopSettingsStrings strings) {
    return _SettingsListPage(
      children: [
        _SettingsSection(
          children: [
            _SettingsInfoRow(
              title: strings.t('cacheSize'),
              value: _prefsLoaded && _cacheSize.isNotEmpty
                  ? _cacheSize
                  : strings.t('calculating'),
            ),
            _SettingsInfoRow(
              title: strings.t('downloadsFolder'),
              value: _downloadsFolder.isEmpty
                  ? strings.t('systemDefault')
                  : _downloadsFolder,
            ),
            _SettingsActionRow(
              title: strings.t('clearCache'),
              value: strings.t('clearCacheSubtitle'),
              actionLabel: strings.t('clear'),
              onPressed: () => _clearCache(strings),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalls(_DesktopSettingsStrings strings) {
    return _SettingsListPage(
      children: [
        _SettingsSection(
          children: [
            _SettingsInfoRow(
              title: strings.t('microphoneDevice'),
              value: strings.t('systemDefault'),
            ),
            _SettingsInfoRow(
              title: strings.t('speakerDevice'),
              value: strings.t('systemDefault'),
            ),
            _SettingsInfoRow(
              title: strings.t('cameraDevice'),
              value: strings.t('systemDefault'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecurity(_DesktopSettingsStrings strings) {
    return _SettingsListPage(
      children: [
        _SettingsSection(
          children: [
            _SettingsNavigationRow(
              title: strings.t('activeSessions'),
              subtitle: strings.t('activeSessionsSubtitle'),
              onTap: () => _unsupported(strings),
            ),
            _SettingsNavigationRow(
              title: strings.t('twoFactor'),
              subtitle: strings.t('twoFactorSubtitle'),
              onTap: () => _unsupported(strings),
            ),
            _SettingsNavigationRow(
              title: strings.t('securityDevices'),
              subtitle: strings.t('securityDevicesSubtitle'),
              onTap: () => _unsupported(strings),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHotkeys(_DesktopSettingsStrings strings) {
    return _SettingsListPage(
      children: [
        _SettingsSection(
          children: [
            _SettingsInfoRow(title: strings.t('newChat'), value: 'Ctrl + N'),
            _SettingsInfoRow(title: strings.t('search'), value: 'Ctrl + K'),
            _SettingsInfoRow(title: strings.t('refresh'), value: 'Ctrl + R'),
            _SettingsInfoRow(title: strings.t('back'), value: 'Esc'),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguage(_DesktopSettingsStrings strings) {
    final language = ref.watch(languageNotifierProvider).currentLanguage;

    return _SettingsListPage(
      children: [
        _SettingsSection(
          children: [
            _LanguageRow(
              title: strings.t('russian'),
              subtitle: 'RU',
              selected: language == 'ru',
              onTap: () => _setLanguage('ru', strings),
            ),
            _LanguageRow(
              title: strings.t('polish'),
              subtitle: 'PL',
              selected: language == 'pl',
              onTap: () => _setLanguage('pl', strings),
            ),
            _LanguageRow(
              title: strings.t('english'),
              subtitle: 'EN',
              selected: language == 'en',
              onTap: () => _setLanguage('en', strings),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAbout(_DesktopSettingsStrings strings) {
    return _SettingsListPage(
      children: [
        _SettingsSection(
          children: [
            _SettingsInfoRow(title: strings.t('appName'), value: 'DARKKICK'),
            _SettingsInfoRow(
              title: strings.t('desktopMode'),
              value: strings.t('windowsDesktop'),
            ),
            _SettingsInfoRow(
              title: strings.t('support'),
              value: strings.t('supportSubtitle'),
            ),
          ],
        ),
      ],
    );
  }

  Future<UserModel?> _loadProfile() async {
    final userId =
        widget.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.trim().isEmpty) return null;

    try {
      return await UserService.getUserData(userId);
    } catch (error, stackTrace) {
      appLogger.e(
        'Desktop settings failed to load profile',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloads = await getDownloadsDirectory();
      final temp = await getTemporaryDirectory();
      final cacheSize = await _directorySize(temp);

      if (!mounted) return;
      setState(() {
        _accent = prefs.getString(_accentPref) ?? 'purple';
        _fontScale = prefs.getDouble(_fontScalePref) ?? 1;
        _compactMode = prefs.getBool(_compactPref) ?? false;
        _enterToSend = prefs.getBool(_enterToSendPref) ?? true;
        _autoDownload = prefs.getBool(_autoDownloadPref) ?? true;
        _stickerPreview = prefs.getBool(_stickerPreviewPref) ?? true;
        _linkPreview = prefs.getBool(_linkPreviewPref) ?? true;
        _desktopNotifications =
            prefs.getBool(_desktopNotificationsPref) ?? true;
        _notificationSound = prefs.getBool(_soundPref) ?? true;
        _mentionsOnly = prefs.getBool(_mentionsPref) ?? false;
        _dndMode = prefs.getBool(_dndPref) ?? false;
        _onlineVisibility = prefs.getBool(_onlineVisibilityPref) ?? true;
        _readReceipts = prefs.getBool(_readReceiptsPref) ?? true;
        _downloadsFolder = downloads?.path ?? '';
        _cacheSize = _formatBytes(cacheSize);
        _prefsLoaded = true;
      });
    } catch (error, stackTrace) {
      appLogger.e(
        'Desktop settings failed to load local preferences',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) setState(() => _prefsLoaded = true);
    }
  }

  Future<int> _directorySize(Directory directory) async {
    var total = 0;
    try {
      if (!await directory.exists()) return 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    } catch (error) {
      appLogger.w('Desktop settings cache size scan skipped: $error');
    }
    return total;
  }

  Future<void> _changeAvatar() async {
    if (_busy) return;
    final strings = _DesktopSettingsStrings.of(context);

    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Images',
            extensions: ['jpg', 'jpeg', 'png', 'webp'],
            mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
          ),
        ],
      );
      if (file == null) return;

      if (!mounted) return;
      setState(() => _busy = true);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw Exception('Selected avatar is empty');

      final url = await StorageService.uploadUserAvatar(
        SelectedMedia(bytes: bytes, name: file.name, path: file.path),
      );
      await UserService.updateUserData(photoURL: url);
      if (!mounted) return;
      setState(() => _profileFuture = _loadProfile());
      _showMessage(strings.t('avatarUpdated'));
    } catch (error, stackTrace) {
      appLogger.e(
        'Desktop settings avatar update failed',
        error: error,
        stackTrace: stackTrace,
      );
      _showMessage('${strings.t('avatarFailed')}: ${_friendlyError(error)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editText({
    required String title,
    required String initialValue,
    required Future<void> Function(String value) onSave,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final strings = _DesktopSettingsStrings.of(context);

    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DarkKickColors.panel,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: maxLines,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: DarkKickColors.deepBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;

    await _runAction(() async {
      await onSave(value);
      if (mounted) setState(() => _profileFuture = _loadProfile());
    }, strings);
  }

  Future<void> _confirmDeleteAccount(_DesktopSettingsStrings strings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DarkKickColors.panel,
        title: Text(
          strings.t('deleteAccount'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          strings.t('deleteAccountConfirm'),
          style: const TextStyle(color: DarkKickColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.t('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runAction(() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      await user.delete();
    }, strings);
  }

  Future<void> _clearCache(_DesktopSettingsStrings strings) async {
    await _runAction(() async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      final temp = await getTemporaryDirectory();
      final size = await _directorySize(temp);
      if (mounted) setState(() => _cacheSize = _formatBytes(size));
    }, strings);
  }

  Future<void> _setBoolPref(String key, bool value, VoidCallback mutate) async {
    await _runAction(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      if (mounted) setState(mutate);
    }, _DesktopSettingsStrings.of(context));
  }

  Future<void> _setDoublePref(
    String key,
    double value,
    VoidCallback mutate,
  ) async {
    await _runAction(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, value);
      if (mounted) setState(mutate);
    }, _DesktopSettingsStrings.of(context));
  }

  Future<void> _setStringPref(
    String key,
    String value,
    VoidCallback mutate,
  ) async {
    await _runAction(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      if (mounted) setState(mutate);
    }, _DesktopSettingsStrings.of(context));
  }

  Future<void> _setLanguage(
    String language,
    _DesktopSettingsStrings strings,
  ) async {
    await _runAction(() async {
      await ref.read(languageNotifierProvider.notifier).setLanguage(language);
    }, strings);
  }

  Future<void> _runAction(
    FutureOr<void> Function() action,
    _DesktopSettingsStrings strings,
  ) async {
    try {
      await action();
    } on FirebaseException catch (error, stackTrace) {
      appLogger.e(
        'Desktop settings Firebase action failed: ${error.code}',
        error: error,
        stackTrace: stackTrace,
      );
      _showMessage(_friendlyError(error));
    } catch (error, stackTrace) {
      appLogger.e(
        'Desktop settings action failed',
        error: error,
        stackTrace: stackTrace,
      );
      _showMessage(_friendlyError(error));
    }
  }

  void _selectCategory(_SettingsCategory category) {
    if (!mounted) return;
    setState(() => _category = category);
  }

  void _unsupported(_DesktopSettingsStrings strings) {
    try {
      _showMessage(strings.t('notAvailableDesktop'));
    } catch (error, stackTrace) {
      appLogger.e(
        'Desktop settings unsupported action failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _displayName(
    UserModel? profile,
    User? authUser,
    _DesktopSettingsStrings strings,
  ) {
    final name = profile?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    final authName = authUser?.displayName?.trim();
    if (authName != null && authName.isNotEmpty) return authName;
    return strings.t('unknownUser');
  }

  String _username(UserModel? profile, User? authUser) {
    final raw = profile?.username?.trim().isNotEmpty == true
        ? profile!.username!.trim()
        : profile?.tag?.trim().isNotEmpty == true
        ? profile!.tag!.trim()
        : authUser?.email?.split('@').first.trim() ?? '';
    return raw.isEmpty ? '@darkkick' : '@$raw';
  }

  String _email(UserModel? profile, User? authUser, _DesktopSettingsStrings s) {
    final email = profile?.email.trim().isNotEmpty == true
        ? profile!.email.trim()
        : authUser?.email?.trim() ?? '';
    return email.isEmpty ? s.t('notSet') : email;
  }

  String _safe(String? value, String fallback) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(value >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
  }

  String _friendlyError(Object error) {
    if (error is FirebaseException) {
      return error.message ?? error.code;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}

class _DesktopSettingsStrings {
  const _DesktopSettingsStrings(this.code);

  final String code;

  static _DesktopSettingsStrings of(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode.toLowerCase();
    if (_values.containsKey(language)) return _DesktopSettingsStrings(language);
    return const _DesktopSettingsStrings('en');
  }

  String t(String key) => _values[code]?[key] ?? _values['en']![key] ?? key;

  String titleFor(_SettingsCategory category) {
    return switch (category) {
      _SettingsCategory.account => t('account'),
      _SettingsCategory.appearance => t('appearance'),
      _SettingsCategory.chats => t('chats'),
      _SettingsCategory.notifications => t('notifications'),
      _SettingsCategory.privacy => t('privacy'),
      _SettingsCategory.storage => t('storage'),
      _SettingsCategory.calls => t('calls'),
      _SettingsCategory.security => t('security'),
      _SettingsCategory.hotkeys => t('hotkeys'),
      _SettingsCategory.language => t('language'),
      _SettingsCategory.about => t('about'),
    };
  }

  String subtitleFor(_SettingsCategory category) {
    return switch (category) {
      _SettingsCategory.account => t('accountSubtitle'),
      _SettingsCategory.appearance => t('appearanceSubtitle'),
      _SettingsCategory.chats => t('chatsSubtitle'),
      _SettingsCategory.notifications => t('notificationsSubtitle'),
      _SettingsCategory.privacy => t('privacySubtitle'),
      _SettingsCategory.storage => t('storageSubtitle'),
      _SettingsCategory.calls => t('callsSubtitle'),
      _SettingsCategory.security => t('securitySubtitle'),
      _SettingsCategory.hotkeys => t('hotkeysSubtitle'),
      _SettingsCategory.language => t('languageSubtitle'),
      _SettingsCategory.about => t('aboutSubtitle'),
    };
  }

  static const _values = {
    'en': {
      'settings': 'Settings',
      'account': 'Account',
      'appearance': 'Appearance',
      'chats': 'Chats',
      'notifications': 'Notifications',
      'privacy': 'Privacy',
      'storage': 'Storage',
      'calls': 'Calls',
      'security': 'Security',
      'hotkeys': 'Hotkeys',
      'language': 'Language',
      'about': 'About DARKKICK',
      'accountSubtitle': 'Profile, username, email, avatar',
      'appearanceSubtitle': 'Theme, accent, font, interface',
      'chatsSubtitle': 'Sending, media, stickers, previews',
      'notificationsSubtitle': 'Sound, banners, mentions',
      'privacySubtitle': 'Visibility, statuses, blocks',
      'storageSubtitle': 'Cache, folders, cleanup',
      'callsSubtitle': 'Microphone, speakers, camera',
      'securitySubtitle': 'Sessions, 2FA, devices',
      'hotkeysSubtitle': 'Fast actions and navigation',
      'languageSubtitle': 'English, Russian, Polish',
      'aboutSubtitle': 'Version, updates, support',
      'unknownUser': 'DARKKICK user',
      'online': 'Online',
      'changeProfile': 'Change profile',
      'uploadAvatar': 'Upload avatar',
      'username': 'Username',
      'email': 'Email',
      'bio': 'Bio',
      'notSet': 'Not set',
      'change': 'Change',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'accountManagement': 'Account management',
      'activeSessions': 'Active sessions',
      'activeSessionsSubtitle': 'Review and end active sign-ins',
      'twoFactor': 'Two-factor authentication',
      'twoFactorSubtitle': 'Additional account protection',
      'disabled': 'Disabled',
      'exportData': 'Export data',
      'exportDataSubtitle': 'Download your DARKKICK account data',
      'deleteAccount': 'Delete account',
      'deleteAccountSubtitle': 'Permanently delete account and data',
      'deleteAccountConfirm':
          'This will ask Firebase to delete the signed-in account. You may need to sign in again first.',
      'darkTheme': 'Dark theme',
      'darkThemeSubtitle': 'Use the desktop dark interface',
      'accentColor': 'Accent color',
      'fontScale': 'Font scale',
      'compactMode': 'Compact mode',
      'compactModeSubtitle': 'Reduce desktop spacing',
      'enterToSend': 'Enter to send',
      'enterToSendSubtitle': 'Use Enter for sending text messages',
      'mediaAutoDownload': 'Media auto-download',
      'mediaAutoDownloadSubtitle': 'Prepare images and files automatically',
      'stickerSettings': 'Sticker settings',
      'stickerSettingsSubtitle': 'Show sticker previews in chat',
      'previewSettings': 'Preview settings',
      'previewSettingsSubtitle': 'Show rich previews when available',
      'desktopNotifications': 'Desktop notifications',
      'desktopNotificationsSubtitle': 'Show Windows notification banners',
      'sound': 'Sound',
      'soundSubtitle': 'Play a sound for new messages',
      'mentions': 'Mentions',
      'mentionsSubtitle': 'Prioritize mentions and direct replies',
      'dndMode': 'DND mode',
      'dndModeSubtitle': 'Silence desktop notifications',
      'onlineVisibility': 'Online visibility',
      'onlineVisibilitySubtitle': 'Show your online status',
      'readReceipts': 'Read receipts',
      'readReceiptsSubtitle': 'Send read state when messages are opened',
      'blockedContacts': 'Blocked contacts',
      'blockedContactsSubtitle': 'Manage blocked people',
      'cacheSize': 'Cache size',
      'downloadsFolder': 'Downloads folder',
      'clearCache': 'Clear cache',
      'clearCacheSubtitle': 'Clear in-memory image cache',
      'clear': 'Clear',
      'calculating': 'Calculating...',
      'systemDefault': 'System default',
      'microphoneDevice': 'Microphone device',
      'speakerDevice': 'Speaker device',
      'cameraDevice': 'Camera device',
      'securityDevices': 'Trusted devices',
      'securityDevicesSubtitle': 'Desktop device management',
      'newChat': 'New chat',
      'search': 'Search',
      'refresh': 'Refresh',
      'back': 'Back',
      'russian': 'Russian',
      'polish': 'Polish',
      'english': 'English',
      'appName': 'Application',
      'desktopMode': 'Desktop mode',
      'windowsDesktop': 'Windows desktop',
      'support': 'Support',
      'supportSubtitle': 'DARKKICK desktop support',
      'notAvailableDesktop': 'Not available on desktop yet',
      'avatarUpdated': 'Avatar updated',
      'avatarFailed': 'Avatar update failed',
      'settingsUnavailable': 'Settings unavailable',
      'settingsUnavailableSubtitle': 'This settings section failed safely.',
    },
    'ru': {
      'settings': 'Настройки',
      'account': 'Аккаунт',
      'appearance': 'Внешний вид',
      'chats': 'Чаты',
      'notifications': 'Уведомления',
      'privacy': 'Конфиденциальность',
      'storage': 'Данные и хранилище',
      'calls': 'Звонки',
      'security': 'Безопасность',
      'hotkeys': 'Горячие клавиши',
      'language': 'Язык',
      'about': 'О DARKKICK',
      'accountSubtitle': 'Профиль, username, email, аватар',
      'appearanceSubtitle': 'Тема, цвет, шрифт, интерфейс',
      'chatsSubtitle': 'Отправка, медиа, стикеры, превью',
      'notificationsSubtitle': 'Звук, баннеры, упоминания',
      'privacySubtitle': 'Видимость, статусы, блокировки',
      'storageSubtitle': 'Кэш, папки, очистка',
      'callsSubtitle': 'Микрофон, динамики, камера',
      'securitySubtitle': 'Сессии, 2FA, устройства',
      'hotkeysSubtitle': 'Быстрые действия и навигация',
      'languageSubtitle': 'Русский, Polish, English',
      'aboutSubtitle': 'Версия, обновления, поддержка',
      'unknownUser': 'Пользователь DARKKICK',
      'online': 'В сети',
      'changeProfile': 'Изменить профиль',
      'uploadAvatar': 'Загрузить аватар',
      'username': 'Username',
      'email': 'Email',
      'bio': 'О себе',
      'notSet': 'Не задано',
      'change': 'Изменить',
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'delete': 'Удалить',
      'accountManagement': 'Управление аккаунтом',
      'activeSessions': 'Активные сессии',
      'activeSessionsSubtitle': 'Посмотреть и завершить активные сеансы',
      'twoFactor': 'Двухфакторная аутентификация',
      'twoFactorSubtitle': 'Дополнительная защита аккаунта',
      'disabled': 'Отключено',
      'exportData': 'Экспорт данных',
      'exportDataSubtitle': 'Скачать свои данные из DARKKICK',
      'deleteAccount': 'Удалить аккаунт',
      'deleteAccountSubtitle': 'Безвозвратно удалить аккаунт и данные',
      'deleteAccountConfirm':
          'Firebase попробует удалить текущий аккаунт. Может потребоваться повторный вход.',
      'darkTheme': 'Темная тема',
      'darkThemeSubtitle': 'Использовать темный desktop-интерфейс',
      'accentColor': 'Акцентный цвет',
      'fontScale': 'Масштаб шрифта',
      'compactMode': 'Компактный режим',
      'compactModeSubtitle': 'Уменьшить интервалы интерфейса',
      'enterToSend': 'Enter для отправки',
      'enterToSendSubtitle': 'Отправлять текст клавишей Enter',
      'mediaAutoDownload': 'Автозагрузка медиа',
      'mediaAutoDownloadSubtitle': 'Подготавливать изображения и файлы',
      'stickerSettings': 'Настройки стикеров',
      'stickerSettingsSubtitle': 'Показывать превью стикеров',
      'previewSettings': 'Настройки превью',
      'previewSettingsSubtitle': 'Показывать расширенные превью',
      'desktopNotifications': 'Desktop-уведомления',
      'desktopNotificationsSubtitle': 'Показывать уведомления Windows',
      'sound': 'Звук',
      'soundSubtitle': 'Проигрывать звук новых сообщений',
      'mentions': 'Упоминания',
      'mentionsSubtitle': 'Выделять упоминания и прямые ответы',
      'dndMode': 'Не беспокоить',
      'dndModeSubtitle': 'Отключить desktop-уведомления',
      'onlineVisibility': 'Видимость онлайн',
      'onlineVisibilitySubtitle': 'Показывать статус в сети',
      'readReceipts': 'Отчеты о прочтении',
      'readReceiptsSubtitle': 'Отправлять статус прочтения',
      'blockedContacts': 'Заблокированные контакты',
      'blockedContactsSubtitle': 'Управление заблокированными людьми',
      'cacheSize': 'Размер кэша',
      'downloadsFolder': 'Папка загрузок',
      'clearCache': 'Очистить кэш',
      'clearCacheSubtitle': 'Очистить кэш изображений в памяти',
      'clear': 'Очистить',
      'calculating': 'Подсчет...',
      'systemDefault': 'Системное устройство',
      'microphoneDevice': 'Микрофон',
      'speakerDevice': 'Динамики',
      'cameraDevice': 'Камера',
      'securityDevices': 'Доверенные устройства',
      'securityDevicesSubtitle': 'Управление desktop-устройствами',
      'newChat': 'Новый чат',
      'search': 'Поиск',
      'refresh': 'Обновить',
      'back': 'Назад',
      'russian': 'Русский',
      'polish': 'Польский',
      'english': 'Английский',
      'appName': 'Приложение',
      'desktopMode': 'Desktop-режим',
      'windowsDesktop': 'Windows desktop',
      'support': 'Поддержка',
      'supportSubtitle': 'Поддержка DARKKICK Desktop',
      'notAvailableDesktop': 'Пока недоступно на desktop',
      'avatarUpdated': 'Аватар обновлен',
      'avatarFailed': 'Не удалось обновить аватар',
      'settingsUnavailable': 'Настройки недоступны',
      'settingsUnavailableSubtitle': 'Этот раздел безопасно отключен.',
    },
    'pl': {
      'settings': 'Ustawienia',
      'account': 'Konto',
      'appearance': 'Wygląd',
      'chats': 'Czaty',
      'notifications': 'Powiadomienia',
      'privacy': 'Prywatność',
      'storage': 'Dane i pamięć',
      'calls': 'Połączenia',
      'security': 'Bezpieczeństwo',
      'hotkeys': 'Skróty',
      'language': 'Język',
      'about': 'O DARKKICK',
      'accountSubtitle': 'Profil, username, email, avatar',
      'appearanceSubtitle': 'Motyw, kolor, font, interfejs',
      'chatsSubtitle': 'Wysyłanie, media, naklejki, podgląd',
      'notificationsSubtitle': 'Dźwięk, banery, wzmianki',
      'privacySubtitle': 'Widoczność, statusy, blokady',
      'storageSubtitle': 'Cache, foldery, czyszczenie',
      'callsSubtitle': 'Mikrofon, głośniki, kamera',
      'securitySubtitle': 'Sesje, 2FA, urządzenia',
      'hotkeysSubtitle': 'Szybkie akcje i nawigacja',
      'languageSubtitle': 'Polski, rosyjski, angielski',
      'aboutSubtitle': 'Wersja, aktualizacje, wsparcie',
      'unknownUser': 'Użytkownik DARKKICK',
      'online': 'Online',
      'changeProfile': 'Zmień profil',
      'uploadAvatar': 'Prześlij avatar',
      'username': 'Username',
      'email': 'Email',
      'bio': 'Bio',
      'notSet': 'Nie ustawiono',
      'change': 'Zmień',
      'save': 'Zapisz',
      'cancel': 'Anuluj',
      'delete': 'Usuń',
      'accountManagement': 'Zarządzanie kontem',
      'activeSessions': 'Aktywne sesje',
      'activeSessionsSubtitle': 'Zobacz i zakończ aktywne logowania',
      'twoFactor': 'Uwierzytelnianie 2FA',
      'twoFactorSubtitle': 'Dodatkowa ochrona konta',
      'disabled': 'Wyłączone',
      'exportData': 'Eksport danych',
      'exportDataSubtitle': 'Pobierz dane konta DARKKICK',
      'deleteAccount': 'Usuń konto',
      'deleteAccountSubtitle': 'Trwale usuń konto i dane',
      'deleteAccountConfirm':
          'Firebase spróbuje usunąć zalogowane konto. Może być wymagane ponowne logowanie.',
      'darkTheme': 'Ciemny motyw',
      'darkThemeSubtitle': 'Użyj ciemnego interfejsu desktop',
      'accentColor': 'Kolor akcentu',
      'fontScale': 'Skala fontu',
      'compactMode': 'Tryb kompaktowy',
      'compactModeSubtitle': 'Zmniejsz odstępy interfejsu',
      'enterToSend': 'Enter wysyła',
      'enterToSendSubtitle': 'Używaj Enter do wysyłania wiadomości',
      'mediaAutoDownload': 'Auto-pobieranie mediów',
      'mediaAutoDownloadSubtitle': 'Przygotowuj obrazy i pliki automatycznie',
      'stickerSettings': 'Ustawienia naklejek',
      'stickerSettingsSubtitle': 'Pokazuj podgląd naklejek',
      'previewSettings': 'Ustawienia podglądu',
      'previewSettingsSubtitle': 'Pokazuj bogate podglądy',
      'desktopNotifications': 'Powiadomienia desktop',
      'desktopNotificationsSubtitle': 'Pokazuj banery Windows',
      'sound': 'Dźwięk',
      'soundSubtitle': 'Odtwarzaj dźwięk nowych wiadomości',
      'mentions': 'Wzmianki',
      'mentionsSubtitle': 'Priorytet dla wzmianek i odpowiedzi',
      'dndMode': 'Tryb DND',
      'dndModeSubtitle': 'Wycisz powiadomienia desktop',
      'onlineVisibility': 'Widoczność online',
      'onlineVisibilitySubtitle': 'Pokazuj status online',
      'readReceipts': 'Potwierdzenia odczytu',
      'readReceiptsSubtitle': 'Wysyłaj stan odczytu wiadomości',
      'blockedContacts': 'Zablokowane kontakty',
      'blockedContactsSubtitle': 'Zarządzaj zablokowanymi osobami',
      'cacheSize': 'Rozmiar cache',
      'downloadsFolder': 'Folder pobrań',
      'clearCache': 'Wyczyść cache',
      'clearCacheSubtitle': 'Wyczyść pamięć obrazów',
      'clear': 'Wyczyść',
      'calculating': 'Liczenie...',
      'systemDefault': 'Domyślne systemowe',
      'microphoneDevice': 'Mikrofon',
      'speakerDevice': 'Głośnik',
      'cameraDevice': 'Kamera',
      'securityDevices': 'Zaufane urządzenia',
      'securityDevicesSubtitle': 'Zarządzanie urządzeniami desktop',
      'newChat': 'Nowy czat',
      'search': 'Szukaj',
      'refresh': 'Odśwież',
      'back': 'Wstecz',
      'russian': 'Rosyjski',
      'polish': 'Polski',
      'english': 'Angielski',
      'appName': 'Aplikacja',
      'desktopMode': 'Tryb desktop',
      'windowsDesktop': 'Windows desktop',
      'support': 'Wsparcie',
      'supportSubtitle': 'Wsparcie DARKKICK Desktop',
      'notAvailableDesktop': 'Jeszcze niedostępne na desktop',
      'avatarUpdated': 'Avatar zaktualizowany',
      'avatarFailed': 'Nie udało się zaktualizować avatara',
      'settingsUnavailable': 'Ustawienia niedostępne',
      'settingsUnavailableSubtitle': 'Ta sekcja została bezpiecznie wyłączona.',
    },
  };
}

class _SettingsNavigation extends StatelessWidget {
  const _SettingsNavigation({
    required this.selected,
    required this.profile,
    required this.authUser,
    required this.onSelected,
  });

  final _SettingsCategory selected;
  final UserModel? profile;
  final User? authUser;
  final ValueChanged<_SettingsCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = _DesktopSettingsStrings.of(context);
    final items = _SettingsCategory.values;
    final name = (profile?.name.trim().isNotEmpty == true)
        ? profile!.name.trim()
        : authUser?.displayName?.trim().isNotEmpty == true
        ? authUser!.displayName!.trim()
        : strings.t('unknownUser');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 16, 18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              strings.t('settings'),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final category = items[index];
              return _SettingsNavItem(
                category: category,
                selected: category == selected,
                onTap: () => onSelected(category),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: _MiniProfileFooter(name: name, authUser: authUser),
        ),
      ],
    );
  }
}

class _SettingsNavItem extends StatelessWidget {
  const _SettingsNavItem({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final _SettingsCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = _DesktopSettingsStrings.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? DarkKickColors.neonPurple.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? DarkKickColors.neonPurple.withValues(alpha: 0.34)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _iconFor(category),
                  color: selected
                      ? DarkKickColors.electricPurple
                      : DarkKickColors.textTertiary,
                  size: 23,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.titleFor(category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : DarkKickColors.textPrimary,
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        strings.subtitleFor(category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DarkKickColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(_SettingsCategory category) {
    return switch (category) {
      _SettingsCategory.account => Icons.person_outline,
      _SettingsCategory.appearance => Icons.palette_outlined,
      _SettingsCategory.chats => Icons.chat_bubble_outline,
      _SettingsCategory.notifications => Icons.notifications_none,
      _SettingsCategory.privacy => Icons.lock_outline,
      _SettingsCategory.storage => Icons.folder_outlined,
      _SettingsCategory.calls => Icons.call_outlined,
      _SettingsCategory.security => Icons.shield_outlined,
      _SettingsCategory.hotkeys => Icons.keyboard_outlined,
      _SettingsCategory.language => Icons.language_outlined,
      _SettingsCategory.about => Icons.info_outline,
    };
  }
}

class _SettingsMainPane extends StatelessWidget {
  const _SettingsMainPane({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: DarkKickColors.divider)),
          ),
          child: Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _SettingsListPage extends StatelessWidget {
  const _SettingsListPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
              child: Text(
                title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: DarkKickColors.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _AccountHero extends StatelessWidget {
  const _AccountHero({
    required this.displayName,
    required this.username,
    required this.email,
    required this.photoUrl,
    required this.busy,
    required this.onChangeAvatar,
    required this.onEditProfile,
  });

  final String displayName;
  final String username;
  final String email;
  final String? photoUrl;
  final bool busy;
  final VoidCallback onChangeAvatar;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final strings = _DesktopSettingsStrings.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _SettingsAvatar(
                  photoUrl: photoUrl,
                  title: displayName,
                  size: 112,
                ),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: IconButton.filled(
                    onPressed: busy ? null : onChangeAvatar,
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_outlined, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: DarkKickColors.cardSoft,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    username,
                    style: const TextStyle(
                      color: DarkKickColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DarkKickColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: DarkKickColors.online,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        strings.t('online'),
                        style: const TextStyle(
                          color: DarkKickColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            _SecondaryButton(
              label: strings.t('changeProfile'),
              onPressed: busy ? null : onEditProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsAvatar extends StatelessWidget {
  const _SettingsAvatar({
    required this.photoUrl,
    required this.title,
    required this.size,
  });

  final String? photoUrl;
  final String title;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = title.trim().isEmpty ? 'D' : title.trim()[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DarkKickColors.cardSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: DarkKickColors.neonPurple.withValues(alpha: 0.4),
        ),
      ),
      child: photoUrl == null || photoUrl!.isEmpty
          ? Center(
              child: Text(
                initial,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: photoUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Center(
                child: Text(
                  initial,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.title,
    required this.value,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String value;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _BaseSettingsRow(
      title: title,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DarkKickColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 18),
          _SecondaryButton(label: actionLabel, onPressed: onPressed),
        ],
      ),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  const _SettingsInfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _BaseSettingsRow(
      title: title,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: DarkKickColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _BaseSettingsRow(
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: DarkKickColors.electricPurple,
      ),
    );
  }
}

class _SettingsSliderRow extends StatelessWidget {
  const _SettingsSliderRow({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return _BaseSettingsRow(
      title: title,
      trailing: SizedBox(
        width: 280,
        child: Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                activeColor: DarkKickColors.neonPurple,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '${(value * 100).round()}%',
                textAlign: TextAlign.right,
                style: const TextStyle(color: DarkKickColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentColorRow extends StatelessWidget {
  const _AccentColorRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const accents = {
      'purple': DarkKickColors.neonPurple,
      'blue': Color(0xFF7DD3FC),
      'green': DarkKickColors.online,
    };

    return _BaseSettingsRow(
      title: title,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: accents.entries.map((entry) {
          final selected = value == entry.key;
          return Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Tooltip(
              message: entry.key,
              child: InkWell(
                onTap: () => onChanged(entry.key),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: entry.value,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
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

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingsNavigationRow(
      title: title,
      subtitle: subtitle,
      trailing: selected
          ? const Icon(Icons.check_circle, color: DarkKickColors.online)
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsNavigationRow extends StatelessWidget {
  const _SettingsNavigationRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: _BaseSettingsRow(
        title: title,
        subtitle: subtitle,
        titleColor: danger ? const Color(0xFFFF8A8A) : Colors.white,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) ...[trailing!, const SizedBox(width: 14)],
            const Icon(
              Icons.chevron_right_rounded,
              color: DarkKickColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _BaseSettingsRow extends StatelessWidget {
  const _BaseSettingsRow({
    required this.title,
    required this.trailing,
    this.subtitle,
    this.titleColor = Colors.white,
  });

  final String title;
  final String? subtitle;
  final Widget trailing;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DarkKickColors.textSecondary,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 18),
          trailing,
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      child: Text(label),
    );
  }
}

class _MiniProfileFooter extends StatelessWidget {
  const _MiniProfileFooter({required this.name, required this.authUser});

  final String name;
  final User? authUser;

  @override
  Widget build(BuildContext context) {
    final photoUrl = authUser?.photoURL;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DarkKickColors.panel.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _SettingsAvatar(photoUrl: photoUrl, title: name, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  authUser?.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DarkKickColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: DarkKickColors.electricPurple, size: 44),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DarkKickColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
