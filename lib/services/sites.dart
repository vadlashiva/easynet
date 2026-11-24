import 'models.dart';

// Official and everyday websites EasyNet can suggest while the user types.
// keywords include English, Hindi and Kannada words people may type.
class Site {
  final String name;
  final String url;
  final List<String> keywords;
  const Site(this.name, this.url, this.keywords);

  String get host => Uri.parse(url).host.replaceFirst(RegExp(r'^www\.'), '');
}

class Sites {
  static const directory = <Site>[
    Site('IRCTC – train tickets', 'https://www.irctc.co.in',
        ['train', 'ticket', 'railway', 'irctc', 'booking', 'tatkal', 'ट्रेन', 'टिकट', 'रेल', 'ರೈಲು', 'ಟಿಕೆಟ್']),
    Site('PNR status (Indian Railways)', 'https://www.indianrail.gov.in/enquiry/PNR/PnrEnquiry.html',
        ['pnr', 'train status', 'railway', 'पीएनआर', 'ಪಿಎನ್‌ಆರ್']),
    Site('Aadhaar (UIDAI)', 'https://myaadhaar.uidai.gov.in',
        ['aadhaar', 'aadhar', 'uidai', 'e-aadhaar', 'आधार', 'ಆಧಾರ್']),
    Site('Income Tax e-Filing (PAN, ITR)', 'https://www.incometax.gov.in',
        ['income tax', 'itr', 'pan', 'tax', 'आयकर', 'पैन', 'ಆದಾಯ ತೆರಿಗೆ', 'ಪ್ಯಾನ್']),
    Site('PAN card – apply (Protean)', 'https://www.onlineservices.nsdl.com/paam/endUserRegisterContact.html',
        ['pan card', 'pan', 'nsdl', 'protean', 'पैन कार्ड', 'ಪ್ಯಾನ್ ಕಾರ್ಡ್']),
    Site('Passport Seva', 'https://www.passportindia.gov.in',
        ['passport', 'पासपोर्ट', 'ಪಾಸ್‌ಪೋರ್ಟ್']),
    Site('DigiLocker', 'https://www.digilocker.gov.in',
        ['digilocker', 'documents', 'marks card', 'certificate', 'डिजिलॉकर', 'ಡಿಜಿಲಾಕರ್']),
    Site('Voter services (ECI)', 'https://voters.eci.gov.in',
        ['voter', 'voter id', 'epic', 'election', 'मतदाता', 'वोटर', 'ಮತದಾರ']),
    Site('Parivahan – driving licence, vehicle', 'https://parivahan.gov.in',
        ['driving licence', 'license', 'dl', 'rc', 'vehicle', 'parivahan', 'ड्राइविंग', 'वाहन', 'ಚಾಲನಾ', 'ವಾಹನ']),
    Site('EPFO – PF', 'https://www.epfindia.gov.in',
        ['pf', 'epf', 'epfo', 'provident fund', 'uan', 'पीएफ', 'ಪಿಎಫ್']),
    Site('GESCOM – electricity bill', 'https://gescom.karnataka.gov.in',
        ['electricity', 'current bill', 'power bill', 'gescom', 'bill', 'बिजली', 'ವಿದ್ಯುತ್', 'ಕರೆಂಟ್ ಬಿಲ್']),
    Site('BESCOM – electricity bill', 'https://bescom.karnataka.gov.in',
        ['electricity', 'bescom', 'bangalore', 'bill', 'ವಿದ್ಯುತ್']),
    Site('Seva Sindhu – Karnataka services', 'https://sevasindhu.karnataka.gov.in',
        ['seva sindhu', 'caste certificate', 'income certificate', 'karnataka', 'ಸೇವಾ ಸಿಂಧು', 'ಪ್ರಮಾಣಪತ್ರ']),
    Site('Bhoomi – land records (RTC)', 'https://landrecords.karnataka.gov.in',
        ['bhoomi', 'land', 'rtc', 'pahani', 'ಭೂಮಿ', 'ಪಹಣಿ', 'जमीन']),
    Site('PM-Kisan', 'https://pmkisan.gov.in',
        ['kisan', 'farmer', 'pm kisan', 'किसान', 'ರೈತ', 'ಕಿಸಾನ್']),
    Site('Ayushman Bharat card', 'https://beneficiary.nha.gov.in',
        ['ayushman', 'health card', 'pmjay', 'आयुष्मान', 'ಆಯುಷ್ಮಾನ್']),
    Site('National Scholarship Portal', 'https://scholarships.gov.in',
        ['scholarship', 'nsp', 'छात्रवृत्ति', 'ವಿದ್ಯಾರ್ಥಿವೇತನ']),
    Site('SSP – Karnataka scholarship', 'https://ssp.postmatric.karnataka.gov.in',
        ['ssp', 'scholarship', 'karnataka', 'ವಿದ್ಯಾರ್ಥಿವೇತನ']),
    Site('Karnataka exam results', 'https://karresults.nic.in',
        ['result', 'sslc', 'puc', 'karresults', 'ಫಲಿತಾಂಶ', 'रिजल्ट']),
    Site('KEA – CET', 'https://cetonline.karnataka.gov.in/kea',
        ['kea', 'cet', 'counselling', 'ಸಿಇಟಿ']),
    Site('Cyber crime – report fraud', 'https://cybercrime.gov.in',
        ['cyber', 'fraud', 'scam', 'complaint', 'साइबर', 'धोखा', 'ಸೈಬರ್', 'ವಂಚನೆ']),
    Site('India Post – tracking', 'https://www.indiapost.gov.in',
        ['post', 'speed post', 'tracking', 'courier', 'डाक', 'ಅಂಚೆ']),
    Site('Consumer helpline', 'https://consumerhelpline.gov.in',
        ['consumer', 'complaint', 'refund', 'उपभोक्ता', 'ಗ್ರಾಹಕ']),
    Site('GST portal', 'https://www.gst.gov.in', ['gst', 'जीएसटी', 'ಜಿಎಸ್‌ಟಿ']),
    Site('UMANG – all govt services', 'https://web.umang.gov.in', ['umang', 'government', 'सरकारी', 'ಸರ್ಕಾರಿ']),
    Site('e-Shram card', 'https://eshram.gov.in', ['eshram', 'e-shram', 'labour', 'श्रम', 'ಕಾರ್ಮಿಕ']),
    Site('RTI online', 'https://rtionline.gov.in', ['rti', 'right to information']),
    Site('Google', 'https://www.google.com', ['google', 'search', 'गूगल', 'ಗೂಗಲ್']),
    Site('YouTube', 'https://www.youtube.com', ['youtube', 'video', 'यूट्यूब', 'ಯೂಟ್ಯೂಬ್']),
    Site('Gmail', 'https://mail.google.com', ['gmail', 'email', 'mail', 'ईमेल', 'ಇಮೇಲ್']),
    Site('WhatsApp Web', 'https://web.whatsapp.com', ['whatsapp', 'व्हाट्सएप', 'ವಾಟ್ಸಾಪ್']),
  ];

  static final _urlLike = RegExp(
    r'^(https?://)?([a-z0-9-]+\.)+[a-z]{2,}(:\d+)?(/\S*)?$',
    caseSensitive: false,
  );

  /// If [text] looks like a web address, returns it as a full https URL.
  static String? asUrl(String text) {
    final t = text.trim();
    if (t.isEmpty || t.contains(' ') || t.contains('@')) return null;
    if (!_urlLike.hasMatch(t)) return null;
    return t.toLowerCase().startsWith('http') ? t : 'https://$t';
  }

  /// Websites matching what the user has typed: their recent sites first.
  static List<Source> suggest(String query, List<Source> recent, {int max = 5}) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];
    final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final scored = <MapEntry<Source, int>>[];
    final seen = <String>{};

    int score(String name, String host, List<String> keywords) {
      final hay = [name.toLowerCase(), host, ...keywords.map((k) => k.toLowerCase())];
      var s = 0;
      for (final w in words) {
        if (host.startsWith(w) || name.toLowerCase().startsWith(w)) {
          s += 3;
        } else if (hay.any((h) => h.startsWith(w) || h.contains(' $w') || (w.length >= 3 && h.contains(w)))) {
          s += 2;
        } else if (keywords.any((k) => w.contains(k.toLowerCase()) && k.length >= 3)) {
          s += 1; // the sentence mentions a keyword, e.g. "how to pay electricity bill"
        }
      }
      return s;
    }

    for (final r in recent) {
      final host = (Uri.tryParse(r.url)?.host ?? '').replaceFirst(RegExp(r'^www\.'), '');
      final s = score(r.title, host, const []);
      if (s > 0 && seen.add(host)) scored.add(MapEntry(r, s + 1));
    }
    for (final site in directory) {
      final s = score(site.name, site.host, site.keywords);
      if (s > 0 && seen.add(site.host)) {
        scored.add(MapEntry(Source(title: site.name, url: site.url), s));
      }
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(max).map((e) => e.key).toList();
  }
}
