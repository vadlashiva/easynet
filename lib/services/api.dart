import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

// Talks to the EasyNet server, which holds the Gemini key.
// Set the address at build time: --dart-define=API_URL=https://your-app.vercel.app
class Api {
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://easynet.vercel.app',
  );

  static Future<Message> ask({
    required String lang,
    required List<Message> history,
    String mode = 'general',
    String? imageBase64,
    String imageMime = 'image/jpeg',
  }) async {
    // Send only the last 12 turns to keep requests small.
    final recent = history.length > 12 ? history.sublist(history.length - 12) : history;
    final body = jsonEncode({
      'lang': lang,
      'mode': mode,
      'messages': recent.map((m) => {'role': m.role, 'text': m.text}).toList(),
      if (imageBase64 != null) 'image': {'mime': imageMime, 'data': imageBase64},
    });

    final res = await http
        .post(
          Uri.parse('$baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 90));

    if (res.statusCode != 200) {
      throw Exception('Server error ${res.statusCode}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final answer = (data['answer'] ?? '').toString().trim();
    if (answer.isEmpty) throw Exception('Empty answer');
    final sources = ((data['sources'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Source.fromJson(Map<String, dynamic>.from(m)))
        .where((s) => s.url.startsWith('http'))
        .toList();
    Reminder? reminder;
    final r = data['reminder'];
    if (r is Map && r['title'] != null && r['date'] != null) {
      reminder = Reminder(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: r['title'].toString(),
        date: r['date'].toString(),
      );
    }
    return Message(role: 'model', text: answer, sources: sources, reminder: reminder);
  }
}
