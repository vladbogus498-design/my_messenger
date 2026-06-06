import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/media_availability_service.dart';
import '../theme/darkkick_colors.dart';

class MediaStatsCard extends StatefulWidget {
  const MediaStatsCard({super.key, this.chatId});

  final String? chatId;

  @override
  State<MediaStatsCard> createState() => _MediaStatsCardState();
}

class _MediaStatsCardState extends State<MediaStatsCard> {
  String? _lastSignature;
  Future<MediaStats>? _statsFuture;

  @override
  Widget build(BuildContext context) {
    final id = widget.chatId?.trim();
    if (id == null || id.isEmpty) {
      return const _StatsView(stats: MediaStats.zero);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(id)
          .collection('messages')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _StatsView(stats: MediaStats.zero);
        }

        final docs = snapshot.data?.docs ?? const [];
        final signature = docs
            .map((doc) {
              final data = doc.data();
              return [
                doc.id,
                data['type'],
                data['imageUrl'],
                data['fileUrl'],
                data['text'],
              ].join('|');
            })
            .join('#');

        if (_lastSignature != signature) {
          _lastSignature = signature;
          _statsFuture = MediaStats.fromMessages(docs.map((doc) => doc.data()));
        }

        return FutureBuilder<MediaStats>(
          future: _statsFuture,
          builder: (context, statsSnapshot) {
            return _StatsView(stats: statsSnapshot.data ?? MediaStats.zero);
          },
        );
      },
    );
  }
}

class MediaStats {
  const MediaStats({
    required this.photos,
    required this.files,
    required this.links,
  });

  static const zero = MediaStats(photos: 0, files: 0, links: 0);
  static final _urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);

  final int photos;
  final int files;
  final int links;

  static Future<MediaStats> fromMessages(
    Iterable<Map<String, dynamic>> messages,
  ) async {
    var photos = 0;
    var files = 0;
    var links = 0;

    for (final message in messages) {
      final type = (message['type'] ?? '').toString();
      final text = (message['text'] ?? '').toString();
      final imageUrl = (message['imageUrl'] ?? '').toString().trim();
      final fileUrl = (message['fileUrl'] ?? '').toString().trim();

      if (imageUrl.isNotEmpty &&
          (type == 'image' || message.containsKey('imageUrl')) &&
          await MediaAvailabilityService.exists(imageUrl)) {
        photos++;
      }
      if (fileUrl.isNotEmpty &&
          (type == 'file' || message.containsKey('fileUrl')) &&
          await MediaAvailabilityService.exists(fileUrl)) {
        files++;
      }
      if (_urlPattern.hasMatch(text)) links++;
    }

    return MediaStats(
      photos: photos,
      files: files,
      links: links,
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView({required this.stats});

  final MediaStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Фотографии', stats.photos),
      ('Файлы', stats.files),
      ('Ссылки', stats.links),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: DarkKickColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DarkKickColors.divider),
      ),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Column(
                  children: [
                    Text(
                      item.$1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: DarkKickColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.$2.toString(),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
