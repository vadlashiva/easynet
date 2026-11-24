import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

// Keeps chats and the chosen language on this device only.
class Storage {
  static const _chatsKey = 'easynet_chats_v1';
  static const _langKey = 'easynet_lang';
  static const maxChats = 50;

  static Future<List<Chat>> loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chatsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      final chats = list
          .whereType<Map>()
          .map((m) => Chat.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      chats.sort((a, b) => b.updatedMs.compareTo(a.updatedMs));
      return chats;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveChat(Chat chat) async {
    final chats = await loadChats();
    chats.removeWhere((c) => c.id == chat.id);
    chats.insert(0, chat);
    final kept = chats.take(maxChats).map((c) => c.toJson()).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatsKey, jsonEncode(kept));
  }

  static Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatsKey);
  }

  static Future<String?> loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey);
  }

  static Future<void> saveLang(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, code);
  }
}
