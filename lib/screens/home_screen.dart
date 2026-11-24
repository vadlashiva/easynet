import 'package:flutter/material.dart';

import '../lang.dart';
import '../services/models.dart';
import '../services/storage.dart';
import '../services/voice.dart';
import 'chat_screen.dart';
import 'lang_picker.dart';
import 'privacy_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppLang lang;
  final ValueChanged<AppLang> onLangChanged;
  const HomeScreen({super.key, required this.lang, required this.onLangChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _text = TextEditingController();
  List<Chat> _recent = [];
  bool _listening = false;

  AppLang get lang => widget.lang;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _text.dispose();
    Voice.instance.stopListening();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final chats = await Storage.loadChats();
    if (mounted) setState(() => _recent = chats);
  }

  Future<void> _open({String? question, Chat? chat}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(lang: lang, firstQuestion: question, chat: chat),
    ));
    _loadRecent();
  }

  void _submit() {
    final q = _text.text.trim();
    if (q.isEmpty) return;
    _text.clear();
    _open(question: q);
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await Voice.instance.stopListening();
      setState(() => _listening = false);
      return;
    }
    final ok = await Voice.instance.listen(
      localeId: lang.speechLocale,
      onText: (words, isFinal) {
        if (!mounted) return;
        setState(() => _text.text = words);
        if (isFinal) {
          setState(() => _listening = false);
          if (words.trim().isNotEmpty) _submit();
        }
      },
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(lang.t('mic_denied'))));
    } else {
      setState(() => _listening = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('EasyNet', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: lang.t('privacy'),
            icon: const Icon(Icons.shield_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PrivacyScreen(lang: lang)));
              _loadRecent();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(lang.t('tagline'),
                style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Center(
              child: LangPicker(lang: lang, onChanged: widget.onLangChanged),
            ),
            const SizedBox(height: 28),
            Text(lang.t('hello'),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 112,
                height: 112,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: _listening ? scheme.error : scheme.primary,
                  ),
                  onPressed: _toggleMic,
                  child: Icon(_listening ? Icons.stop : Icons.mic, size: 52),
                ),
              ),
            ),
            if (_listening) ...[
              const SizedBox(height: 8),
              Text(lang.t('listening'), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _text,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: lang.t('ask_hint'),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _submit,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(lang.t('suggested'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final s in lang.suggestions)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lightbulb_outline),
                  title: Text(s),
                  onTap: () => _open(question: s),
                ),
              ),
            const SizedBox(height: 24),
            Text(lang.t('recent'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_recent.isEmpty)
              Text(lang.t('no_recent'),
                  style: TextStyle(color: scheme.onSurfaceVariant))
            else
              for (final c in _recent.take(10))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => _open(chat: c),
                ),
          ],
        ),
      ),
    );
  }
}
