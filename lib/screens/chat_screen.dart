import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../lang.dart';
import '../services/api.dart';
import '../services/links.dart';
import '../services/models.dart';
import '../services/storage.dart';
import '../services/voice.dart';

class ChatScreen extends StatefulWidget {
  final AppLang lang;
  final String? firstQuestion;
  final Chat? chat;
  const ChatScreen({super.key, required this.lang, this.firstQuestion, this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final Chat _chat;
  final _text = TextEditingController();
  final _scroll = ScrollController();
  bool _busy = false;
  bool _failed = false;
  bool _listening = false;
  int? _speakingIndex;

  AppLang get lang => widget.lang;

  @override
  void initState() {
    super.initState();
    _chat = widget.chat ??
        Chat(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: widget.firstQuestion ?? '',
          lang: lang.code,
          updatedMs: DateTime.now().millisecondsSinceEpoch,
        );
    final q = widget.firstQuestion;
    if (q != null && q.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(q));
    }
  }

  @override
  void dispose() {
    Voice.instance.stopSpeaking();
    Voice.instance.stopListening();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String q) async {
    q = q.trim();
    if (q.isEmpty || _busy) return;
    setState(() {
      _chat.messages.add(Message(role: 'user', text: q));
      if (_chat.title.isEmpty) _chat.title = q;
      _failed = false;
    });
    await _ask();
  }

  Future<void> _ask() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    _scrollDown();
    try {
      final answer = await Api.ask(lang: lang.code, history: _chat.messages);
      if (!mounted) return;
      setState(() => _chat.messages.add(answer));
      _chat.lang = lang.code;
      _chat.updatedMs = DateTime.now().millisecondsSinceEpoch;
      await Storage.saveChat(_chat);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
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
          final q = _text.text;
          _text.clear();
          _send(q);
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

  Future<void> _toggleSpeak(int i, String text) async {
    if (_speakingIndex == i) {
      await Voice.instance.stopSpeaking();
      setState(() => _speakingIndex = null);
      return;
    }
    setState(() => _speakingIndex = i);
    await Voice.instance.speak(text, lang.ttsLocale, onDone: () {
      if (mounted) setState(() => _speakingIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final msgs = _chat.messages;
    return Scaffold(
      appBar: AppBar(
        title: Text(_chat.title.isEmpty ? lang.t('new_task') : _chat.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length + 1,
                itemBuilder: (context, i) {
                  if (i == msgs.length) return _footer(scheme);
                  final m = msgs[i];
                  return m.isUser ? _userBubble(m, scheme) : _answerCard(i, m, scheme);
                },
              ),
            ),
            _inputBar(scheme),
          ],
        ),
      ),
    );
  }

  Widget _footer(ColorScheme scheme) {
    if (_busy) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Text(lang.t('thinking')),
        ]),
      );
    }
    if (_failed) {
      return Card(
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lang.t('error')),
            TextButton(onPressed: _ask, child: Text(lang.t('retry'))),
          ]),
        ),
      );
    }
    if (_chat.messages.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(lang.t('disclaimer'),
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _userBubble(Message m, ColorScheme scheme) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(m.text),
      ),
    );
  }

  Widget _answerCard(int i, Message m, ColorScheme scheme) {
    final speaking = _speakingIndex == i;
    final links = Links.find(m.text, m.sources);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(Links.clean(m.text), style: const TextStyle(height: 1.5)),
            if (links.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(lang.t('open_site'),
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final s in links)
                    ActionChip(
                      avatar: const Icon(Icons.open_in_new, size: 18),
                      label: Text(s.title, overflow: TextOverflow.ellipsis),
                      onPressed: () => _openLink(s.url),
                    ),
                ],
              ),
            ],
            Row(children: [
              TextButton.icon(
                icon: Icon(speaking ? Icons.stop : Icons.volume_up_outlined),
                label: Text(speaking ? lang.t('stop') : lang.t('speak')),
                onPressed: () => _toggleSpeak(i, m.text),
              ),
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: Text(lang.t('copy')),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: Links.clean(m.text)));
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(lang.t('copied'))));
                  }
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _inputBar(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(children: [
        IconButton.filled(
          style: IconButton.styleFrom(
              backgroundColor: _listening ? scheme.error : scheme.primary),
          icon: Icon(_listening ? Icons.stop : Icons.mic),
          onPressed: _busy ? null : _toggleMic,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _text,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (v) {
              _text.clear();
              _send(v);
            },
            decoration: InputDecoration(
              hintText: _listening ? lang.t('listening') : lang.t('ask_hint'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: _busy
              ? null
              : () {
                  final q = _text.text;
                  _text.clear();
                  _send(q);
                },
        ),
      ]),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    var ok = false;
    if (uri != null) {
      try {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok) ok = await launchUrl(uri);
      } catch (_) {
        ok = false;
      }
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(lang.t('open_failed'))));
    }
  }
}
