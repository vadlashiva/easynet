import 'package:flutter/material.dart';

import '../lang.dart';
import '../services/models.dart';
import '../services/opener.dart';
import '../services/storage.dart';

// Saved reminders, soonest first, with days left.
class RemindersScreen extends StatefulWidget {
  final AppLang lang;
  const RemindersScreen({super.key, required this.lang});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

/// "Due today", "3 days left" or "Date passed".
String dueText(AppLang lang, Reminder r) {
  final d = r.daysLeft();
  if (d == null) return r.date;
  if (d < 0) return lang.t('date_passed');
  if (d == 0) return lang.t('due_today');
  return lang.t('days_left').replaceAll('{n}', '$d');
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder> _items = [];
  bool _loaded = false;

  AppLang get lang => widget.lang;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await Storage.loadReminders();
    if (mounted) {
      setState(() {
        _items = items;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(lang.t('reminders'))),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(lang.t('no_reminders'), textAlign: TextAlign.center),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final r = _items[i];
                    final left = r.daysLeft() ?? 99;
                    final color = left < 0
                        ? scheme.outline
                        : left <= 2
                            ? scheme.error
                            : scheme.primary;
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.alarm, color: color),
                        title: Text(r.title),
                        subtitle: Text('${r.date}  ·  ${dueText(lang, r)}',
                            style: TextStyle(color: color)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            tooltip: lang.t('add_calendar'),
                            icon: const Icon(Icons.event),
                            onPressed: () => addToCalendar(r),
                          ),
                          IconButton(
                            tooltip: lang.t('delete'),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await Storage.deleteReminder(r.id);
                              _load();
                            },
                          ),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}
