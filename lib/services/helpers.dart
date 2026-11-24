import 'package:flutter/material.dart';

import '../lang.dart';

// The EasyNet helpers ("agents"). Each one sends its id as `mode` to the server,
// which adds that helper's instructions for Gemini.
class Helper {
  final String id;
  final IconData icon;
  final Color color;
  final Map<String, String> title;
  final Map<String, String> intro;
  final Map<String, String> photoQuestion; // sent when the user adds only a photo
  final bool startWithCamera;

  const Helper({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.intro,
    required this.photoQuestion,
    this.startWithCamera = false,
  });

  String titleIn(AppLang l) => title[l.code] ?? title['en']!;
  String introIn(AppLang l) => intro[l.code] ?? intro['en']!;
  String photoQuestionIn(AppLang l) => photoQuestion[l.code] ?? photoQuestion['en']!;

  static Helper? byId(String? id) {
    for (final h in all) {
      if (h.id == id) return h;
    }
    return null;
  }

  static const all = [photo, scam, schemes, form, reminder, farmer];

  static const photo = Helper(
    id: 'photo',
    icon: Icons.photo_camera,
    color: Color(0xFF6A1B9A),
    startWithCamera: true,
    title: {'en': 'Photo search', 'hi': 'फ़ोटो से खोजें', 'kn': 'ಫೋಟೋ ಹುಡುಕಾಟ'},
    intro: {
      'en': 'Take a photo of anything – a product, a sign, a medicine strip, a screen or a plant – and ask what you want to know.',
      'hi': 'किसी भी चीज़ की फ़ोटो लें – सामान, बोर्ड, दवा की पट्टी, स्क्रीन या पौधा – और जो जानना हो पूछें।',
      'kn': 'ಯಾವುದೇ ವಸ್ತುವಿನ ಫೋಟೋ ತೆಗೆಯಿರಿ – ಸಾಮಾನು, ಫಲಕ, ಔಷಧಿ ಪಟ್ಟಿ, ಪರದೆ ಅಥವಾ ಗಿಡ – ಮತ್ತು ತಿಳಿಯಬೇಕಾದ್ದನ್ನು ಕೇಳಿ.',
    },
    photoQuestion: {
      'en': 'What is this? Please explain and tell me how it can help me.',
      'hi': 'यह क्या है? कृपया समझाइए और बताइए यह मेरे किस काम आ सकता है।',
      'kn': 'ಇದು ಏನು? ದಯವಿಟ್ಟು ವಿವರಿಸಿ ಮತ್ತು ಇದು ನನಗೆ ಹೇಗೆ ಉಪಯೋಗ ಎಂದು ತಿಳಿಸಿ.',
    },
  );

  static const scam = Helper(
    id: 'scam',
    icon: Icons.gpp_maybe,
    color: Color(0xFFC62828),
    title: {'en': 'Scam checker', 'hi': 'धोखा जाँचें', 'kn': 'ವಂಚನೆ ಪರೀಕ್ಷೆ'},
    intro: {
      'en': 'Got a strange SMS, WhatsApp message, call or link? Paste it here or send a screenshot. I will tell you if it looks like a scam. Do not click the link first.',
      'hi': 'कोई अजीब SMS, WhatsApp संदेश, कॉल या लिंक आया? यहाँ चिपकाएँ या स्क्रीनशॉट भेजें। मैं बताऊँगा कि यह धोखा लगता है या नहीं। पहले लिंक पर क्लिक न करें।',
      'kn': 'ವಿಚಿತ್ರ SMS, WhatsApp ಸಂದೇಶ, ಕರೆ ಅಥವಾ ಲಿಂಕ್ ಬಂತೇ? ಇಲ್ಲಿ ಅಂಟಿಸಿ ಅಥವಾ ಸ್ಕ್ರೀನ್‌ಶಾಟ್ ಕಳುಹಿಸಿ. ಇದು ವಂಚನೆಯೇ ಎಂದು ಹೇಳುತ್ತೇನೆ. ಮೊದಲು ಲಿಂಕ್ ಒತ್ತಬೇಡಿ.',
    },
    photoQuestion: {
      'en': 'Is this message or screen a scam? What should I do?',
      'hi': 'क्या यह संदेश या स्क्रीन धोखा है? मुझे क्या करना चाहिए?',
      'kn': 'ಈ ಸಂದೇಶ ಅಥವಾ ಪರದೆ ವಂಚನೆಯೇ? ನಾನು ಏನು ಮಾಡಬೇಕು?',
    },
  );

  static const schemes = Helper(
    id: 'schemes',
    icon: Icons.volunteer_activism,
    color: Color(0xFF2E7D32),
    title: {'en': 'Scheme finder', 'hi': 'योजना खोजें', 'kn': 'ಯೋಜನೆ ಹುಡುಕಿ'},
    intro: {
      'en': 'Tell me a little about yourself – your state, age, work (farmer, student, worker…) and whether you have a BPL card. I will find government schemes you may get.',
      'hi': 'अपने बारे में थोड़ा बताइए – राज्य, उम्र, काम (किसान, छात्र, मज़दूर…) और क्या आपके पास BPL कार्ड है। मैं आपके लिए सरकारी योजनाएँ खोजूँगा।',
      'kn': 'ನಿಮ್ಮ ಬಗ್ಗೆ ಸ್ವಲ್ಪ ಹೇಳಿ – ರಾಜ್ಯ, ವಯಸ್ಸು, ಕೆಲಸ (ರೈತ, ವಿದ್ಯಾರ್ಥಿ, ಕಾರ್ಮಿಕ…) ಮತ್ತು BPL ಕಾರ್ಡ್ ಇದೆಯೇ. ನಿಮಗೆ ಸಿಗಬಹುದಾದ ಸರ್ಕಾರಿ ಯೋಜನೆಗಳನ್ನು ಹುಡುಕುತ್ತೇನೆ.',
    },
    photoQuestion: {
      'en': 'Which government scheme is this about, and can I apply?',
      'hi': 'यह किस सरकारी योजना के बारे में है, और क्या मैं आवेदन कर सकता हूँ?',
      'kn': 'ಇದು ಯಾವ ಸರ್ಕಾರಿ ಯೋಜನೆ, ನಾನು ಅರ್ಜಿ ಹಾಕಬಹುದೇ?',
    },
  );

  static const form = Helper(
    id: 'form',
    icon: Icons.description,
    color: Color(0xFF1565C0),
    startWithCamera: true,
    title: {'en': 'Form & letter helper', 'hi': 'फ़ॉर्म और पत्र सहायक', 'kn': 'ಅರ್ಜಿ ಮತ್ತು ಪತ್ರ ಸಹಾಯಕ'},
    intro: {
      'en': 'Take a photo of a form, notice, bill or government letter. I will explain it in simple words and tell you what to do. Cover Aadhaar, card and bank numbers before the photo.',
      'hi': 'किसी फ़ॉर्म, नोटिस, बिल या सरकारी पत्र की फ़ोटो लें। मैं उसे आसान शब्दों में समझाऊँगा और बताऊँगा क्या करना है। फ़ोटो से पहले आधार, कार्ड और बैंक नंबर ढक दें।',
      'kn': 'ಅರ್ಜಿ, ನೋಟಿಸ್, ಬಿಲ್ ಅಥವಾ ಸರ್ಕಾರಿ ಪತ್ರದ ಫೋಟೋ ತೆಗೆಯಿರಿ. ಸರಳವಾಗಿ ವಿವರಿಸಿ ಏನು ಮಾಡಬೇಕು ಎಂದು ಹೇಳುತ್ತೇನೆ. ಫೋಟೋ ಮೊದಲು ಆಧಾರ್, ಕಾರ್ಡ್ ಮತ್ತು ಬ್ಯಾಂಕ್ ಸಂಖ್ಯೆಗಳನ್ನು ಮುಚ್ಚಿ.',
    },
    photoQuestion: {
      'en': 'Please explain this document in simple words and tell me what I need to do.',
      'hi': 'कृपया इस काग़ज़ को आसान शब्दों में समझाइए और बताइए मुझे क्या करना है।',
      'kn': 'ದಯವಿಟ್ಟು ಈ ದಾಖಲೆಯನ್ನು ಸರಳವಾಗಿ ವಿವರಿಸಿ ಮತ್ತು ನಾನು ಏನು ಮಾಡಬೇಕು ಎಂದು ಹೇಳಿ.',
    },
  );

  static const reminder = Helper(
    id: 'reminder',
    icon: Icons.alarm,
    color: Color(0xFFEF6C00),
    title: {'en': 'Bill & date reminder', 'hi': 'बिल और तारीख़ याद', 'kn': 'ಬಿಲ್ ಮತ್ತು ದಿನಾಂಕ ನೆನಪು'},
    intro: {
      'en': 'Take a photo of a bill, ticket or notice, or type what you must remember (for example "LIC premium on 5 December"). I will find the date and save a reminder.',
      'hi': 'बिल, टिकट या नोटिस की फ़ोटो लें, या लिखें क्या याद रखना है (जैसे "5 दिसंबर को LIC प्रीमियम")। मैं तारीख़ निकालकर याद सहेजूँगा।',
      'kn': 'ಬಿಲ್, ಟಿಕೆಟ್ ಅಥವಾ ನೋಟಿಸ್ ಫೋಟೋ ತೆಗೆಯಿರಿ, ಅಥವಾ ನೆನಪಿಡಬೇಕಾದ್ದನ್ನು ಬರೆಯಿರಿ (ಉದಾ: "ಡಿಸೆಂಬರ್ 5ಕ್ಕೆ LIC ಪ್ರೀಮಿಯಂ"). ದಿನಾಂಕ ಹುಡುಕಿ ನೆನಪು ಉಳಿಸುತ್ತೇನೆ.',
    },
    photoQuestion: {
      'en': 'What is the due date and amount here? Please set a reminder.',
      'hi': 'इसमें आख़िरी तारीख़ और रकम क्या है? कृपया याद सेट करें।',
      'kn': 'ಇದರಲ್ಲಿ ಕೊನೆಯ ದಿನಾಂಕ ಮತ್ತು ಮೊತ್ತ ಎಷ್ಟು? ದಯವಿಟ್ಟು ನೆನಪು ಇಡಿ.',
    },
  );

  static const farmer = Helper(
    id: 'farmer',
    icon: Icons.agriculture,
    color: Color(0xFF558B2F),
    title: {'en': 'Farmer helper', 'hi': 'किसान सहायक', 'kn': 'ರೈತ ಸಹಾಯಕ'},
    intro: {
      'en': 'Ask about your crop, pests, fertiliser, water, prices or farm schemes. Tell me your crop and district, or send a photo of the sick plant or leaf.',
      'hi': 'अपनी फ़सल, कीट, खाद, पानी, दाम या किसान योजनाओं के बारे में पूछें। फ़सल और ज़िला बताइए, या बीमार पौधे/पत्ते की फ़ोटो भेजें।',
      'kn': 'ನಿಮ್ಮ ಬೆಳೆ, ಕೀಟ, ಗೊಬ್ಬರ, ನೀರು, ಬೆಲೆ ಅಥವಾ ರೈತ ಯೋಜನೆಗಳ ಬಗ್ಗೆ ಕೇಳಿ. ಬೆಳೆ ಮತ್ತು ಜಿಲ್ಲೆ ತಿಳಿಸಿ, ಅಥವಾ ರೋಗ ಬಂದ ಗಿಡ/ಎಲೆಯ ಫೋಟೋ ಕಳುಹಿಸಿ.',
    },
    photoQuestion: {
      'en': 'What is wrong with this plant and what should I do?',
      'hi': 'इस पौधे को क्या हुआ है और मुझे क्या करना चाहिए?',
      'kn': 'ಈ ಗಿಡಕ್ಕೆ ಏನಾಗಿದೆ ಮತ್ತು ನಾನು ಏನು ಮಾಡಬೇಕು?',
    },
  );
}
