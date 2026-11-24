import 'package:easynet/lang.dart';
import 'package:easynet/services/helpers.dart';
import 'package:easynet/services/links.dart';
import 'package:easynet/services/models.dart';
import 'package:easynet/services/sites.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every language has every on-screen word', () {
    final keys = AppLang.english.words.keys.toSet();
    for (final l in AppLang.all) {
      expect(l.words.keys.toSet(), keys, reason: l.code);
      expect(l.suggestions.length, 4, reason: l.code);
    }
  });

  test('chat survives save and load as JSON', () {
    final c = Chat(id: '1', title: 'PAN', lang: 'kn', updatedMs: 5, messages: [
      const Message(role: 'user', text: 'PAN?'),
      const Message(
          role: 'model',
          text: '1. Go to the site',
          sources: [Source(title: 'Income Tax', url: 'https://incometax.gov.in')]),
    ]);
    final back = Chat.fromJson(c.toJson());
    expect(back.messages.length, 2);
    expect(back.messages.last.sources.first.url, 'https://incometax.gov.in');
    expect(back.lang, 'kn');
  });

  test('finds tappable websites in an answer', () {
    const text = 'Go to **[www.indianrail.gov.in**](https://www.indianrail.gov.in**) '
        'or https://www.irctc.co.in/nget/ and uidai.gov.in. Mail care@irctc.co.in.';
    final links = Links.find(text, const []);
    expect(links.map((l) => Uri.parse(l.url).host).toList(),
        ['www.indianrail.gov.in', 'www.irctc.co.in', 'uidai.gov.in']);
    expect(Links.clean(text), isNot(contains('**')));
    expect(Links.clean(text), isNot(contains('](')));
  });

  test('address bar: web addresses open, words suggest sites', () {
    expect(Sites.asUrl('irctc.co.in'), 'https://irctc.co.in');
    expect(Sites.asUrl('https://uidai.gov.in/x'), 'https://uidai.gov.in/x');
    expect(Sites.asUrl('how to pay bill'), isNull);
    expect(Sites.asUrl('me@gmail.com'), isNull);
    expect(Sites.suggest('aadh', const []).first.url, contains('uidai'));
    expect(Sites.suggest('ಆಧಾರ್', const []).first.url, contains('uidai'));
    expect(Sites.suggest('pnr', const []).first.url, contains('indianrail'));
    final recent = [const Source(title: 'My college', url: 'https://kishkindauniversity.edu.in')];
    expect(Sites.suggest('kishk', recent).first.title, 'My college');
    expect(Sites.suggest('a', const []), isEmpty);
  });

  test('six helpers, each with title, intro and photo question in every language', () {
    expect(Helper.all.length, 6);
    for (final h in Helper.all) {
      for (final l in AppLang.all) {
        expect(h.titleIn(l), isNotEmpty);
        expect(h.title.containsKey(l.code), isTrue, reason: '${h.id} ${l.code}');
        expect(h.intro.containsKey(l.code), isTrue, reason: '${h.id} ${l.code}');
        expect(h.photoQuestion.containsKey(l.code), isTrue, reason: '${h.id} ${l.code}');
      }
    }
    expect(Helper.byId('scam'), Helper.scam);
    expect(Helper.byId('general'), isNull);
  });

  test('reminders: days left and saving inside a chat', () {
    const r = Reminder(id: '1', title: 'Pay bill', date: '2026-12-05');
    expect(r.daysLeft(DateTime(2026, 12, 2, 18)), 3);
    expect(r.daysLeft(DateTime(2026, 12, 5)), 0);
    expect(r.daysLeft(DateTime(2026, 12, 6)), -1);
    final c = Chat(id: 'c', title: 't', lang: 'en', updatedMs: 1, mode: 'reminder', messages: [
      const Message(role: 'user', text: 'bill', photo: true),
      const Message(role: 'model', text: 'ok', reminder: r),
    ]);
    final back = Chat.fromJson(c.toJson());
    expect(back.mode, 'reminder');
    expect(back.messages.first.photo, isTrue);
    expect(back.messages.last.reminder!.date, '2026-12-05');
  });
}
