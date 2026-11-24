// Chat data kept on the phone.
class Source {
  final String title;
  final String url;
  const Source({required this.title, required this.url});

  Map<String, dynamic> toJson() => {'title': title, 'url': url};
  factory Source.fromJson(Map<String, dynamic> j) =>
      Source(title: (j['title'] ?? '').toString(), url: (j['url'] ?? '').toString());
}

class Reminder {
  final String id;
  final String title;
  final String date; // YYYY-MM-DD
  const Reminder({required this.id, required this.title, required this.date});

  DateTime? get day => DateTime.tryParse(date);

  /// Days from today until the date (0 = today, negative = passed).
  int? daysLeft([DateTime? now]) {
    final d = day;
    if (d == null) return null;
    final n = now ?? DateTime.now();
    return DateTime(d.year, d.month, d.day).difference(DateTime(n.year, n.month, n.day)).inDays;
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'date': date};
  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: (j['id'] ?? j['date'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
      );
}

class Message {
  final String role; // 'user' or 'model'
  final String text;
  final List<Source> sources;
  final bool photo; // the user attached a photo to this message
  final Reminder? reminder; // a reminder the reminder helper found
  const Message({
    required this.role,
    required this.text,
    this.sources = const [],
    this.photo = false,
    this.reminder,
  });

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'sources': sources.map((s) => s.toJson()).toList(),
        if (photo) 'photo': true,
        if (reminder != null) 'reminder': reminder!.toJson(),
      };

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        role: (j['role'] ?? 'user').toString(),
        text: (j['text'] ?? '').toString(),
        sources: ((j['sources'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => Source.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        photo: j['photo'] == true,
        reminder: j['reminder'] is Map
            ? Reminder.fromJson(Map<String, dynamic>.from(j['reminder'] as Map))
            : null,
      );
}

class Chat {
  final String id;
  String title;
  String lang;
  String mode; // helper id, or 'general'
  int updatedMs;
  final List<Message> messages;

  Chat({
    required this.id,
    required this.title,
    required this.lang,
    required this.updatedMs,
    this.mode = 'general',
    List<Message>? messages,
  }) : messages = messages ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'lang': lang,
        'mode': mode,
        'updatedMs': updatedMs,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory Chat.fromJson(Map<String, dynamic> j) => Chat(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        lang: (j['lang'] ?? 'en').toString(),
        mode: (j['mode'] ?? 'general').toString(),
        updatedMs: (j['updatedMs'] as num?)?.toInt() ?? 0,
        messages: ((j['messages'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => Message.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
}
