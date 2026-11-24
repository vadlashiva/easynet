import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

// Keeps chats and the chosen language on this device only.
class Storage {
  static const _chatsKey = 'easynet_chats_v1';
  static const _langKey = 'easynet_lang';
  static const _sitesKey = 'easynet_sites_v1';
  static const _remindersKey = 'easynet_reminders_v1';
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
    await prefs.remove(_sitesKey);
    await prefs.remove(_remindersKey);
  }

  // Saved reminders, soonest first.
  static Future<List<Reminder>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_remindersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((m) => Reminder.fromJson(Map<String, dynamic>.from(m)))
          .where((r) => r.day != null)
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveReminders(List<Reminder> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_remindersKey, jsonEncode(list.map((r) => r.toJson()).toList()));
  }

  static Future<void> addReminder(Reminder r) async {
    final list = await loadReminders();
    list.removeWhere((x) => x.id == r.id || (x.title == r.title && x.date == r.date));
    list.add(r);
    await _saveReminders(list);
  }

  static Future<void> deleteReminder(String id) async {
    final list = await loadReminders();
    list.removeWhere((x) => x.id == id);
    await _saveReminders(list);
  }

  // Websites the user opened, newest first, for address-bar suggestions.
  static Future<List<Source>> loadSites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sitesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((m) => Source.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addSite(Source site) async {
    final host = Uri.tryParse(site.url)?.host ?? site.url;
    final sites = await loadSites();
    sites.removeWhere((s) => (Uri.tryParse(s.url)?.host ?? s.url) == host);
    sites.insert(0, site);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _sitesKey, jsonEncode(sites.take(20).map((s) => s.toJson()).toList()));
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
