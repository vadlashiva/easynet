import 'package:flutter/material.dart';

import '../lang.dart';

// English / हिंदी / ಕನ್ನಡ switch.
class LangPicker extends StatelessWidget {
  final AppLang lang;
  final ValueChanged<AppLang> onChanged;
  const LangPicker({super.key, required this.lang, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: [
        for (final l in AppLang.all) ButtonSegment(value: l.code, label: Text(l.name)),
      ],
      selected: {lang.code},
      onSelectionChanged: (s) => onChanged(AppLang.byCode(s.first)),
    );
  }
}
