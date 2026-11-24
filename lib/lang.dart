// The languages EasyNet speaks, with the words shown on screen in each one.
class AppLang {
  final String code; // sent to the server: en, hi, kn
  final String name; // shown in the picker, in its own script
  final String speechLocale; // for speech-to-text
  final String ttsLocale; // for reading answers aloud
  final Map<String, String> words;
  final List<String> suggestions;

  const AppLang({
    required this.code,
    required this.name,
    required this.speechLocale,
    required this.ttsLocale,
    required this.words,
    required this.suggestions,
  });

  String t(String key) => words[key] ?? english.words[key] ?? key;

  static AppLang byCode(String? code) =>
      all.firstWhere((l) => l.code == code, orElse: () => english);

  static const all = [english, hindi, kannada];

  static const english = AppLang(
    code: 'en',
    name: 'English',
    speechLocale: 'en_IN',
    ttsLocale: 'en-IN',
    suggestions: [
      'How do I apply for a PAN card online?',
      'How do I check my train PNR status?',
      'How do I download my Aadhaar card?',
      'How do I pay my electricity bill online?',
    ],
    words: {
      'tagline': 'Your personal assistant for the entire internet',
      'hello': 'What do you want to do online today?',
      'ask_hint': 'Type or tap the mic and speak…',
      'listening': 'Listening… speak now',
      'suggested': 'Try asking',
      'recent': 'Recent tasks',
      'no_recent': 'Your tasks will appear here.',
      'new_task': 'New task',
      'sources': 'Sources',
      'speak': 'Read aloud',
      'stop': 'Stop',
      'copy': 'Copy',
      'copied': 'Copied',
      'thinking': 'Thinking…',
      'error': 'Could not get an answer. Check your internet and try again.',
      'retry': 'Try again',
      'mic_denied':
          'Microphone not available. Allow microphone access, or type instead.',
      'privacy': 'Privacy',
      'privacy_text':
          'EasyNet never asks for passwords, card numbers or OTPs. Do not type them here. Your chats are kept only on this device, and you can delete them any time. Your questions are sent to our server and to Google Gemini to prepare answers.',
      'delete_all': 'Delete all my chats',
      'delete_confirm': 'Delete all chats on this device? This cannot be undone.',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'deleted': 'All chats deleted',
      'disclaimer':
          'EasyNet can make mistakes. Check important details on the official website.',
      'language': 'Language',
    },
  );

  static const hindi = AppLang(
    code: 'hi',
    name: 'हिंदी',
    speechLocale: 'hi_IN',
    ttsLocale: 'hi-IN',
    suggestions: [
      'ऑनलाइन पैन कार्ड के लिए आवेदन कैसे करें?',
      'ट्रेन का PNR स्टेटस कैसे देखें?',
      'अपना आधार कार्ड कैसे डाउनलोड करें?',
      'बिजली का बिल ऑनलाइन कैसे भरें?',
    ],
    words: {
      'tagline': 'पूरे इंटरनेट के लिए आपका निजी सहायक',
      'hello': 'आज आप ऑनलाइन क्या करना चाहते हैं?',
      'ask_hint': 'लिखें या माइक दबाकर बोलें…',
      'listening': 'सुन रहे हैं… अब बोलिए',
      'suggested': 'ऐसे पूछकर देखें',
      'recent': 'हाल के काम',
      'no_recent': 'आपके काम यहाँ दिखेंगे।',
      'new_task': 'नया काम',
      'sources': 'स्रोत',
      'speak': 'सुनें',
      'stop': 'रोकें',
      'copy': 'कॉपी',
      'copied': 'कॉपी हो गया',
      'thinking': 'सोच रहे हैं…',
      'error': 'जवाब नहीं मिल सका। इंटरनेट जाँचें और फिर कोशिश करें।',
      'retry': 'फिर कोशिश करें',
      'mic_denied': 'माइक्रोफ़ोन उपलब्ध नहीं है। अनुमति दें या लिखकर पूछें।',
      'privacy': 'गोपनीयता',
      'privacy_text':
          'EasyNet कभी पासवर्ड, कार्ड नंबर या OTP नहीं माँगता। इन्हें यहाँ न लिखें। आपकी बातचीत सिर्फ़ इसी फ़ोन में रहती है, और आप इसे कभी भी मिटा सकते हैं। जवाब तैयार करने के लिए आपके सवाल हमारे सर्वर और Google Gemini को भेजे जाते हैं।',
      'delete_all': 'मेरी सारी बातचीत मिटाएँ',
      'delete_confirm': 'इस फ़ोन की सारी बातचीत मिटाएँ? यह वापस नहीं होगा।',
      'cancel': 'रद्द करें',
      'delete': 'मिटाएँ',
      'deleted': 'सारी बातचीत मिटा दी गई',
      'disclaimer':
          'EasyNet से गलती हो सकती है। ज़रूरी जानकारी आधिकारिक वेबसाइट पर जाँच लें।',
      'language': 'भाषा',
    },
  );

  static const kannada = AppLang(
    code: 'kn',
    name: 'ಕನ್ನಡ',
    speechLocale: 'kn_IN',
    ttsLocale: 'kn-IN',
    suggestions: [
      'ಆನ್‌ಲೈನ್‌ನಲ್ಲಿ ಪ್ಯಾನ್ ಕಾರ್ಡ್‌ಗೆ ಅರ್ಜಿ ಹಾಕುವುದು ಹೇಗೆ?',
      'ರೈಲಿನ PNR ಸ್ಥಿತಿ ನೋಡುವುದು ಹೇಗೆ?',
      'ನನ್ನ ಆಧಾರ್ ಕಾರ್ಡ್ ಡೌನ್‌ಲೋಡ್ ಮಾಡುವುದು ಹೇಗೆ?',
      'ವಿದ್ಯುತ್ ಬಿಲ್ ಆನ್‌ಲೈನ್‌ನಲ್ಲಿ ಪಾವತಿಸುವುದು ಹೇಗೆ?',
    ],
    words: {
      'tagline': 'ಇಡೀ ಇಂಟರ್ನೆಟ್‌ಗೆ ನಿಮ್ಮ ವೈಯಕ್ತಿಕ ಸಹಾಯಕ',
      'hello': 'ಇಂದು ಆನ್‌ಲೈನ್‌ನಲ್ಲಿ ನೀವು ಏನು ಮಾಡಬೇಕು?',
      'ask_hint': 'ಟೈಪ್ ಮಾಡಿ ಅಥವಾ ಮೈಕ್ ಒತ್ತಿ ಮಾತನಾಡಿ…',
      'listening': 'ಕೇಳುತ್ತಿದ್ದೇವೆ… ಈಗ ಮಾತನಾಡಿ',
      'suggested': 'ಹೀಗೆ ಕೇಳಿ ನೋಡಿ',
      'recent': 'ಇತ್ತೀಚಿನ ಕೆಲಸಗಳು',
      'no_recent': 'ನಿಮ್ಮ ಕೆಲಸಗಳು ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತವೆ.',
      'new_task': 'ಹೊಸ ಕೆಲಸ',
      'sources': 'ಮೂಲಗಳು',
      'speak': 'ಓದಿ ಹೇಳು',
      'stop': 'ನಿಲ್ಲಿಸು',
      'copy': 'ನಕಲಿಸು',
      'copied': 'ನಕಲಿಸಲಾಗಿದೆ',
      'thinking': 'ಯೋಚಿಸುತ್ತಿದ್ದೇವೆ…',
      'error': 'ಉತ್ತರ ಸಿಗಲಿಲ್ಲ. ಇಂಟರ್ನೆಟ್ ಪರಿಶೀಲಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      'retry': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
      'mic_denied': 'ಮೈಕ್ರೊಫೋನ್ ಲಭ್ಯವಿಲ್ಲ. ಅನುಮತಿ ನೀಡಿ ಅಥವಾ ಟೈಪ್ ಮಾಡಿ.',
      'privacy': 'ಗೌಪ್ಯತೆ',
      'privacy_text':
          'EasyNet ಎಂದಿಗೂ ಪಾಸ್‌ವರ್ಡ್, ಕಾರ್ಡ್ ಸಂಖ್ಯೆ ಅಥವಾ OTP ಕೇಳುವುದಿಲ್ಲ. ಅವುಗಳನ್ನು ಇಲ್ಲಿ ಟೈಪ್ ಮಾಡಬೇಡಿ. ನಿಮ್ಮ ಸಂಭಾಷಣೆ ಈ ಫೋನ್‌ನಲ್ಲಿ ಮಾತ್ರ ಇರುತ್ತದೆ, ಯಾವಾಗ ಬೇಕಾದರೂ ಅಳಿಸಬಹುದು. ಉತ್ತರ ಸಿದ್ಧಪಡಿಸಲು ನಿಮ್ಮ ಪ್ರಶ್ನೆಗಳನ್ನು ನಮ್ಮ ಸರ್ವರ್ ಮತ್ತು Google Gemini‌ಗೆ ಕಳುಹಿಸಲಾಗುತ್ತದೆ.',
      'delete_all': 'ನನ್ನ ಎಲ್ಲಾ ಸಂಭಾಷಣೆ ಅಳಿಸಿ',
      'delete_confirm': 'ಈ ಫೋನ್‌ನ ಎಲ್ಲಾ ಸಂಭಾಷಣೆ ಅಳಿಸಬೇಕೆ? ಇದನ್ನು ಹಿಂಪಡೆಯಲು ಆಗುವುದಿಲ್ಲ.',
      'cancel': 'ರದ್ದುಮಾಡಿ',
      'delete': 'ಅಳಿಸಿ',
      'deleted': 'ಎಲ್ಲಾ ಸಂಭಾಷಣೆ ಅಳಿಸಲಾಗಿದೆ',
      'disclaimer':
          'EasyNet ತಪ್ಪು ಮಾಡಬಹುದು. ಮುಖ್ಯ ವಿವರಗಳನ್ನು ಅಧಿಕೃತ ವೆಬ್‌ಸೈಟ್‌ನಲ್ಲಿ ಪರಿಶೀಲಿಸಿ.',
      'language': 'ಭಾಷೆ',
    },
  );
}
