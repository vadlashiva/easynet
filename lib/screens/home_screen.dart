import 'package:flutter/material.dart';

import '../lang.dart';
import '../services/helpers.dart';
import '../services/models.dart';
import '../services/opener.dart';
import '../services/sites.dart';
import '../services/storage.dart';
import '../services/voice.dart';
import 'chat_screen.dart';
import 'lang_picker.dart';
import 'privacy_screen.dart';
import 'reminders_screen.dart';

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
  List<Source> _sites = [];
  List<Reminder> _reminders = [];
  String _query = '';
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
    final sites = await Storage.loadSites();
    final reminders = await Storage.loadReminders();
    if (mounted) {
      setState(() {
        _recent = chats;
        _sites = sites;
        _reminders = reminders;
      });
    }
  }

  Future<void> _open({String? question, Chat? chat, Helper? helper}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          ChatScreen(lang: lang, firstQuestion: question, chat: chat, helper: helper),
    ));
    _loadRecent();
  }

  Future<void> _openReminders() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => RemindersScreen(lang: lang)));
    _loadRecent();
  }

  // Six helper tiles: photo search, scam checker, schemes, forms, reminders, farmer.
  Widget _helpersGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.95,
      children: [
        for (final h in Helper.all)
          Material(
            color: h.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _open(helper: h),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(h.icon, color: h.color, size: 34),
                  const SizedBox(height: 6),
                  Text(h.titleIn(lang),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
      ],
    );
  }

  // Reminders due in the next 7 days.
  List<Widget> _comingUp(ColorScheme scheme) {
    final soon = _reminders.where((r) {
      final d = r.daysLeft();
      return d != null && d >= 0 && d <= 7;
    }).toList();
    if (soon.isEmpty) return const [];
    return [
      const SizedBox(height: 20),
      Text(lang.t('coming_up'), style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      for (final r in soon.take(3))
        Card(
          color: scheme.errorContainer.withValues(alpha: 0.5),
          child: ListTile(
            leading: Icon(Icons.alarm, color: scheme.error),
            title: Text(r.title),
            subtitle: Text('${r.date}  ·  ${dueText(lang, r)}'),
            onTap: _openReminders,
          ),
        ),
    ];
  }

  void _submit() {
    final q = _text.text.trim();
    if (q.isEmpty) return;
    final url = Sites.asUrl(q);
    if (url != null) {
      _openSite(url, null);
      return;
    }
    _clear();
    _open(question: q);
  }

  void _clear() {
    _text.clear();
    setState(() => _query = '');
  }

  Future<void> _openSite(String url, String? title) async {
    final ok = await Opener.open(url, title: title);
    if (!mounted) return;
    if (ok) {
      _clear();
      _loadRecent();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(lang.t('open_failed'))));
    }
  }

  // Address-bar style suggestions shown while typing.
  Widget _suggestions(ColorScheme scheme) {
    final q = _query.trim();
    if (q.isEmpty) return const SizedBox.shrink();
    final url = Sites.asUrl(q);
    final matches = Sites.suggest(q, _sites);
    return Card(
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          if (url != null)
            ListTile(
              leading: Icon(Icons.public, color: scheme.primary),
              title: Text('${lang.t('open')}  ${Uri.parse(url).host}'),
              subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => _openSite(url, null),
            ),
          for (final m in matches)
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(Uri.parse(m.url).host,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _openSite(m.url, m.title),
            ),
          if (url == null)
            ListTile(
              leading: Icon(Icons.auto_awesome, color: scheme.primary),
              title: Text(lang.t('ask_easynet')),
              subtitle: Text(q, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: _submit,
            ),
        ],
      ),
    );
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
        setState(() {
          _text.text = words;
          _query = words;
        });
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
            tooltip: lang.t('reminders'),
            icon: Badge(
              isLabelVisible: _reminders.any((r) => (r.daysLeft() ?? -1) >= 0),
              label: Text('${_reminders.where((r) => (r.daysLeft() ?? -1) >= 0).length}'),
              child: const Icon(Icons.alarm),
            ),
            onPressed: _openReminders,
          ),
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
              textInputAction: TextInputAction.go,
              keyboardType: TextInputType.text,
              autocorrect: false,
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: lang.t('ask_hint'),
                border: const OutlineInputBorder(),
                prefixIcon: IconButton(
                  tooltip: Helper.photo.titleIn(lang),
                  icon: const Icon(Icons.photo_camera_outlined),
                  onPressed: () => _open(helper: Helper.photo),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _submit,
                ),
              ),
            ),
            _suggestions(Theme.of(context).colorScheme),
            ..._comingUp(Theme.of(context).colorScheme),
            const SizedBox(height: 24),
            Text(lang.t('helpers'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _helpersGrid(),
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
                  leading: Icon(Helper.byId(c.mode)?.icon ?? Icons.history,
                      color: Helper.byId(c.mode)?.color),
                  title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => _open(chat: c),
                ),
          ],
        ),
      ),
    );
  }
}
