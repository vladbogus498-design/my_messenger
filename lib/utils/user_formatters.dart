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
    if (isOnline) return 'В сети';
    if (lastSeen == null) return 'Был(а) недавно';

    final local = lastSeen.toLocal();
    final now = DateTime.now();
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    if (isToday) return 'Был(а) сегодня в $time';

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;
    if (isYesterday) return 'Был(а) вчера в $time';

    return 'Был(а) ${registrationDate(local)}';
  }

  static String compactPresence({
    required bool isOnline,
    required DateTime? lastSeen,
  }) {
    if (isOnline) return '● В сети';
    if (lastSeen == null) return 'Был(а) недавно';

    final diff = DateTime.now().difference(lastSeen.toLocal());
    if (diff.inMinutes < 5) return 'Был(а) недавно';
    if (diff.inHours < 24) return 'Был(а) сегодня';
    return 'Был(а) недавно';
  }
}
