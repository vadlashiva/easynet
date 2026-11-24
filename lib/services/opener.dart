import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'storage.dart';

// Opens a website in the phone's browser and remembers it for suggestions.
class Opener {
  static Future<bool> open(String url, {String? title, bool remember = true}) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return false;
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) ok = await launchUrl(uri);
    } catch (_) {
      ok = false;
    }
    if (ok && remember) {
      await Storage.addSite(Source(
        title: (title == null || title.trim().isEmpty) ? uri.host : title.trim(),
        url: uri.toString(),
      ));
    }
    return ok;
  }
}

/// Opens Google Calendar with an all-day event, so the phone reminds the user.
Future<bool> addToCalendar(Reminder r) {
  final d = r.day;
  if (d == null) return Future.value(false);
  String f(DateTime x) =>
      '${x.year.toString().padLeft(4, '0')}${x.month.toString().padLeft(2, '0')}${x.day.toString().padLeft(2, '0')}';
  final next = DateTime(d.year, d.month, d.day + 1);
  final url = Uri.https('calendar.google.com', '/calendar/render', {
    'action': 'TEMPLATE',
    'text': r.title,
    'dates': '${f(d)}/${f(next)}',
    'details': 'Reminder from EasyNet',
  }).toString();
  return Opener.open(url, remember: false);
}
