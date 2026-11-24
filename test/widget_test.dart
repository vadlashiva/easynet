import 'package:easynet/lang.dart';
import 'package:easynet/services/links.dart';
import 'package:easynet/services/models.dart';
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
}
