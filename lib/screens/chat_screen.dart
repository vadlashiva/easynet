import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../lang.dart';
import '../services/api.dart';
import '../services/helpers.dart';
import '../services/links.dart';
import '../services/models.dart';
import '../services/opener.dart';
import '../services/storage.dart';
import '../services/voice.dart';

class ChatScreen extends StatefulWidget {
  final AppLang lang;
  final String? firstQuestion;
  final Chat? chat;
  final Helper? helper;
  const ChatScreen(
      {super.key, required this.lang, this.firstQuestion, this.chat, this.helper});

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

  // Photo waiting to be sent, and photos sent in this session (by message index).
  Uint8List? _photo;
  String _photoMime = 'image/jpeg';
  Uint8List? _sendingPhoto;
  String _sendingMime = 'image/jpeg';
  final Map<int, Uint8List> _photos = {};
  final Set<String> _savedReminders = {};

  AppLang get lang => widget.lang;
  Helper? get helper => widget.helper ?? Helper.byId(_chat.mode);

  @override
  void initState() {
    super.initState();
    _chat = widget.chat ??
        Chat(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: widget.firstQuestion ?? '',
          lang: lang.code,
          mode: widget.helper?.id ?? 'general',
          updatedMs: DateTime.now().millisecondsSinceEpoch,
        );
    final q = widget.firstQuestion;
    if (q != null && q.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(q));
    } else if (widget.chat == null && (widget.helper?.startWithCamera ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _photoMenu());
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
    final photo = _photo;
    if (_busy || (q.isEmpty && photo == null)) return;
    if (q.isEmpty) q = (helper ?? Helper.photo).photoQuestionIn(lang);
    setState(() {
      _chat.messages.add(Message(role: 'user', text: q, photo: photo != null));
      if (photo != null) _photos[_chat.messages.length - 1] = photo;
      if (_chat.title.isEmpty) {
        _chat.title = helper != null ? '${helper!.titleIn(lang)}: $q' : q;
      }
      _sendingPhoto = photo;
      _sendingMime = _photoMime;
      _photo = null;
      _failed = false;
    });
    await _ask();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(
          source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 75);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final name = x.name.toLowerCase();
      final mime = x.mimeType ??
          (name.endsWith('.png')
              ? 'image/png'
              : name.endsWith('.webp')
                  ? 'image/webp'
                  : 'image/jpeg');
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _photoMime = mime;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(lang.t('photo_failed'))));
      }
    }
  }

  Future<void> _photoMenu() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: Text(lang.t('take_photo')),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(lang.t('pick_photo')),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(lang.t('photo_privacy'),
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
          ),
        ]),
      ),
    );
    if (source != null) await _pickPhoto(source);
  }

  Future<void> _saveReminder(Reminder r) async {
    await Storage.addReminder(r);
    if (!mounted) return;
    setState(() => _savedReminders.add(r.id));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(lang.t('reminder_saved'))));
  }

  Future<void> _ask() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    _scrollDown();
    try {
      final photo = _sendingPhoto;
      final answer = await Api.ask(
        lang: lang.code,
        history: _chat.messages,
        mode: _chat.mode,
        imageBase64: photo == null ? null : base64Encode(photo),
        imageMime: _sendingMime,
      );
      if (!mounted) return;
      setState(() {
        _chat.messages.add(answer);
        _sendingPhoto = null;
      });
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
        title: Text(
            _chat.title.isNotEmpty
                ? _chat.title
                : (helper?.titleIn(lang) ?? lang.t('new_task')),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length + 2,
                itemBuilder: (context, j) {
                  if (j == 0) return _intro(scheme);
                  final i = j - 1;
                  if (i == msgs.length) return _footer(scheme);
                  final m = msgs[i];
                  return m.isUser ? _userBubble(i, m, scheme) : _answerCard(i, m, scheme);
                },
              ),
            ),
            _inputBar(scheme),
          ],
        ),
      ),
    );
  }

  // The helper explains what it does at the top of the chat.
  Widget _intro(ColorScheme scheme) {
    final h = helper;
    if (h == null) return const SizedBox.shrink();
    return Card(
      color: h.color.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(h.icon, color: h.color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.titleIn(lang),
                  style: TextStyle(fontWeight: FontWeight.bold, color: h.color)),
              const SizedBox(height: 4),
              Text(h.introIn(lang), style: const TextStyle(height: 1.4)),
            ]),
          ),
        ]),
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

  Widget _userBubble(int i, Message m, ColorScheme scheme) {
    final bytes = _photos[i];
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (bytes != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(bytes, height: 160, fit: BoxFit.cover),
              ),
            )
          else if (m.photo)
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.photo, size: 18),
              const SizedBox(width: 4),
              Text(lang.t('photo')),
            ]),
          SelectableText(m.text),
        ]),
      ),
    );
  }

  Widget _reminderCard(Reminder r, ColorScheme scheme) {
    final saved = _savedReminders.contains(r.id);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Helper.reminder.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Helper.reminder.color.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.alarm, color: Helper.reminder.color),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${r.title}\n${r.date}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          FilledButton.tonalIcon(
            icon: Icon(saved ? Icons.check : Icons.bookmark_add),
            label: Text(saved ? lang.t('reminder_saved') : lang.t('save_reminder')),
            onPressed: saved ? null : () => _saveReminder(r),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.event),
            label: Text(lang.t('add_calendar')),
            onPressed: () async {
              final ok = await addToCalendar(r);
              if (!ok && mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(lang.t('open_failed'))));
              }
            },
          ),
        ]),
      ]),
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
                      onPressed: () => _openLink(s.url, s.title),
                    ),
                ],
              ),
            ],
            if (m.reminder != null) _reminderCard(m.reminder!, scheme),
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
    final photo = _photo;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (photo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(photo, width: 56, height: 56, fit: BoxFit.cover),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(lang.t('photo_added'))),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _photo = null),
              ),
            ]),
          ),
        Row(children: [
        IconButton(
          tooltip: lang.t('photo'),
          icon: const Icon(Icons.add_a_photo_outlined),
          onPressed: _busy ? null : _photoMenu,
        ),
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
      ]),
    );
  }

  Future<void> _openLink(String url, String title) async {
    final ok = await Opener.open(url, title: title);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(lang.t('open_failed'))));
    }
  }
}
