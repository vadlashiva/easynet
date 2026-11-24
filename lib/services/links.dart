import 'models.dart';

// Finds the websites an answer mentions, so each can be opened with one tap.
class Links {
  static final _markdown = RegExp(r'\[([^\]]+)\]\((https?://[^)\s]+)\)');
  static final _url = RegExp(r'https?://[^\s<>()\[\]"*]+', caseSensitive: false);
  static final _domain = RegExp(
    r'\b(?:www\.)?[a-z0-9][a-z0-9-]*(?:\.[a-z0-9-]+)*\.(?:gov\.in|nic\.in|co\.in|org\.in|ac\.in|net\.in|in|com|org|net|gov)\b(?:/[^\s<>()\[\]"*]*)?',
    caseSensitive: false,
  );

  /// Websites in [text] plus [sources], one per site, at most [max].
  static List<Source> find(String text, List<Source> sources, {int max = 5}) {
    final out = <Source>[];
    final seen = <String>{};

    void add(String raw, [String? title]) {
      var u = raw.trim().replaceAll(RegExp(r'[.,;:!?*_)\]]+$'), '');
      if (u.isEmpty) return;
      if (!u.toLowerCase().startsWith('http')) u = 'https://$u';
      final uri = Uri.tryParse(u);
      if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) return;
      final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
      if (host.contains('@') || !seen.add(host)) return;
      final label = (title == null || title.trim().isEmpty || title.contains('*'))
          ? uri.host.toLowerCase()
          : title.trim();
      out.add(Source(title: label, url: uri.toString()));
    }

    for (final s in sources) {
      add(s.url, s.title);
    }
    for (final m in _markdown.allMatches(text)) {
      add(m.group(2)!, m.group(1));
    }
    final noMd = text.replaceAll(_markdown, ' ');
    for (final m in _url.allMatches(noMd)) {
      add(m.group(0)!);
    }
    final noUrls = noMd.replaceAll(_url, ' ');
    for (final m in _domain.allMatches(noUrls)) {
      // Skip e-mail addresses like help@irctc.co.in
      if (m.start > 0 && noUrls[m.start - 1] == '@') continue;
      add(m.group(0)!);
    }
    return out.take(max).toList();
  }

  /// Answer text made readable: markdown links become their text, ** removed.
  static String clean(String s) => s
      .replaceAllMapped(_markdown, (m) {
        final t = m.group(1)!.replaceAll('*', '').trim();
        return t.isEmpty ? m.group(2)! : t;
      })
      .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => m.group(1) ?? '')
      .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*[*-]\s+', multiLine: true), '• ')
      .replaceAll('**', '');
}
