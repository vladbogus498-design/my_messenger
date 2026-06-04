import 'package:http/http.dart' as http;

class MediaAvailabilityService {
  const MediaAvailabilityService._();

  static Future<bool> exists(String? rawUrl) async {
    final url = rawUrl?.trim();
    if (url == null || url.isEmpty) return false;

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;

    try {
      final head = await http.head(uri).timeout(const Duration(seconds: 5));
      if (head.statusCode >= 200 && head.statusCode < 400) return true;
      if (head.statusCode == 404 || head.statusCode == 410) return false;
      if (head.statusCode != 405 && head.statusCode < 500) return false;

      final probe = await http
          .get(uri, headers: const {'Range': 'bytes=0-0'})
          .timeout(const Duration(seconds: 6));
      return probe.statusCode >= 200 && probe.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  static Future<List<String>> filterExisting(Iterable<String> urls) async {
    final result = <String>[];
    final availability = <String, bool>{};

    for (final rawUrl in urls) {
      final url = rawUrl.trim();
      if (url.isEmpty) continue;
      final isAvailable = availability[url] ??= await exists(url);
      if (isAvailable) {
        result.add(url);
      }
    }

    return result;
  }
}
