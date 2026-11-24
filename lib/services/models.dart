// Chat data kept on the phone.
class Source {
  final String title;
  final String url;
  const Source({required this.title, required this.url});

  Map<String, dynamic> toJson() => {'title': title, 'url': url};
  factory Source.fromJson(Map<String, dynamic> j) =>
      Source(title: (j['title'] ?? '').toString(), url: (j['url'] ?? '').toString());
}

class Message {
  final String role; // 'user' or 'model'
  final String text;
  final List<Source> sources;
  const Message({required this.role, required this.text, this.sources = const []});

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'sources': sources.map((s) => s.toJson()).toList(),
      };

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        role: (j['role'] ?? 'user').toString(),
        text: (j['text'] ?? '').toString(),
        sources: ((j['sources'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => Source.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
}

class Chat {
  final String id;
  String title;
  String lang;
  int updatedMs;
  final List<Message> messages;

  Chat({
    required this.id,
    required this.title,
    required this.lang,
    required this.updatedMs,
    List<Message>? messages,
  }) : messages = messages ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'lang': lang,
        'updatedMs': updatedMs,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory Chat.fromJson(Map<String, dynamic> j) => Chat(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        lang: (j['lang'] ?? 'en').toString(),
        updatedMs: (j['updatedMs'] as num?)?.toInt() ?? 0,
        messages: ((j['messages'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => Message.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
}
