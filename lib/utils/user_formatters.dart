import 'package:cloud_firestore/cloud_firestore.dart';

class UserFormatters {
  static const _months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static String registrationDate(DateTime? date) {
    if (date == null) return 'Неизвестно';
    final local = date.toLocal();
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }

  static String chatPresence({
    required bool isOnline,
    required DateTime? lastSeen,
  }) {
    return compactPresence(isOnline: isOnline, lastSeen: lastSeen);
  }

  static String compactPresence({
    required bool isOnline,
    required DateTime? lastSeen,
  }) {
    if (isOnline) return 'В сети';
    if (lastSeen == null) return 'Был(а) недавно';

    final diff = DateTime.now().difference(lastSeen.toLocal());
    if (diff.inMinutes < 5) return 'Был(а) недавно';
    if (diff.inHours < 24) return 'Был(а) сегодня';
    return 'Был(а) недавно';
  }

  static DateTime? readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String? readPhotoUrl(Map<String, dynamic> data) {
    for (final key in const [
      'photoURL',
      'photoUrl',
      'avatarUrl',
      'profileImageUrl',
    ]) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? versionedImageUrl(String? url, DateTime? updatedAt) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (updatedAt == null) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) return trimmed;

    final query = Map<String, String>.from(uri.queryParameters)
      ..['v'] = updatedAt.millisecondsSinceEpoch.toString();
    return uri.replace(queryParameters: query).toString();
  }
}
