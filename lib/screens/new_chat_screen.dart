import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chat_service.dart';
import '../theme/darkkick_colors.dart';
import '../utils/input_validator.dart';
import '../utils/navigation_animations.dart';
import '../utils/user_formatters.dart';
import 'single_chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<_SearchUser> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final raw = _controller.text.trim();
    final query = InputValidator.sanitizeSearchQuery(raw).toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final currentUid = _auth.currentUser?.uid;
      final fields = ['nameLower', 'usernameLower', 'tagLower'];
      final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (final field in fields) {
        final snapshot = await _firestore
            .collection('publicProfiles')
            .where(field, isGreaterThanOrEqualTo: query)
            .where(field, isLessThan: '$query\uf8ff')
            .limit(12)
            .get();
        docs.addAll(snapshot.docs);
      }
      final keywordSnapshot = await _firestore
          .collection('publicProfiles')
          .where('searchKeywords', arrayContains: query)
          .limit(12)
          .get();
      docs.addAll(keywordSnapshot.docs);

      final seen = <String>{};
      final users = <_SearchUser>[];
      for (final doc in docs) {
        if (doc.id == currentUid || !seen.add(doc.id)) continue;
        users.add(_SearchUser.fromDoc(doc));
      }

      if (!mounted) return;
      setState(() => _results = users);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось выполнить поиск. Попробуй позже.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openChat(_SearchUser user) async {
    setState(() => _loading = true);
    try {
      final chatId = await ChatService.createChat(
        otherUserId: user.uid,
        chatName: user.displayName,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        NavigationAnimations.slideFadeRoute(
          SingleChatScreen(
            chatId: chatId,
            chatName: user.displayName,
            otherUserId: user.uid,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось открыть чат.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkKickColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DarkKickColors.darkBackground,
        title: const Text('Новый чат'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Container(
                decoration: BoxDecoration(
                  color: DarkKickColors.panel,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: DarkKickColors.divider),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.search,
                      color: DarkKickColors.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: DarkKickColors.neonPurple,
                        decoration: const InputDecoration(
                          hintText: 'Имя, ник или tag',
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: DarkKickColors.neonPurple,
                      ),
                      onPressed: _loading ? null : _search,
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const LinearProgressIndicator(color: DarkKickColors.neonPurple),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFFF8AA8)),
                ),
              ),
            Expanded(
              child: _results.isEmpty
                  ? _SearchEmptyState(
                      hasQuery: _controller.text.trim().isNotEmpty,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = _results[index];
                        return _UserResultTile(
                          user: user,
                          onTap: () => _openChat(user),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchUser {
  const _SearchUser({
    required this.uid,
    required this.displayName,
    required this.subtitle,
    this.photoURL,
  });

  final String uid;
  final String displayName;
  final String subtitle;
  final String? photoURL;

  factory _SearchUser.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['name'] ?? data['username'] ?? 'Пользователь')
        .toString();
    final tag = (data['tag'] ?? data['username'] ?? '').toString();
    final photoUrl = UserFormatters.readPhotoUrl(data);
    final avatarUpdatedAt = UserFormatters.readDate(data['avatarUpdatedAt']);

    return _SearchUser(
      uid: doc.id,
      displayName: name,
      subtitle: tag.isEmpty ? 'Darkkick user' : tag,
      photoURL: UserFormatters.versionedImageUrl(photoUrl, avatarUpdatedAt),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  const _UserResultTile({required this.user, required this.onTap});

  final _SearchUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.isEmpty
        ? '?'
        : user.displayName[0].toUpperCase();
    final photoUrl = user.photoURL?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarkKickColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DarkKickColors.divider),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: DarkKickColors.cardSoft,
                backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                child: hasPhoto
                    ? null
                    : Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.subtitle,
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
              const Icon(
                Icons.chat_bubble_outline,
                color: DarkKickColors.neonPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_search,
              color: DarkKickColors.neonPurple,
              size: 46,
            ),
            const SizedBox(height: 14),
            Text(
              hasQuery ? 'Никого не нашли' : 'Найди человека',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Введи имя, ник, tag или email.',
              textAlign: TextAlign.center,
              style: TextStyle(color: DarkKickColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
