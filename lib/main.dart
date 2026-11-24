import 'package:flutter/material.dart';

import 'lang.dart';
import 'screens/home_screen.dart';
import 'services/storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EasyNetApp());
}

class EasyNetApp extends StatefulWidget {
  const EasyNetApp({super.key});

  @override
  State<EasyNetApp> createState() => _EasyNetAppState();
}

class _EasyNetAppState extends State<EasyNetApp> {
  AppLang _lang = AppLang.english;

  @override
  void initState() {
    super.initState();
    Storage.loadLang().then((code) {
      if (mounted && code != null) setState(() => _lang = AppLang.byCode(code));
    });
  }

  void _setLang(AppLang l) {
    setState(() => _lang = l);
    Storage.saveLang(l.code);
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1565C0);
    return MaterialApp(
      title: 'EasyNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        // Slightly larger text: many users are new to the internet.
        textTheme: Typography.material2021().black.apply(fontSizeFactor: 1.08),
      ),
      home: HomeScreen(lang: _lang, onLangChanged: _setLang),
    );
  }
}
