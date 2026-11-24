import 'package:flutter/material.dart';

import '../lang.dart';
import '../services/storage.dart';

class PrivacyScreen extends StatelessWidget {
  final AppLang lang;
  const PrivacyScreen({super.key, required this.lang});

  Future<void> _deleteAll(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(lang.t('delete_confirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(lang.t('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(lang.t('delete'))),
        ],
      ),
    );
    if (yes != true) return;
    await Storage.deleteAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(lang.t('deleted'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lang.t('privacy'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.shield_outlined, size: 56),
          const SizedBox(height: 16),
          Text(lang.t('privacy_text'), style: const TextStyle(height: 1.5)),
          const SizedBox(height: 16),
          Text(lang.t('disclaimer'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: Text(lang.t('delete_all')),
            onPressed: () => _deleteAll(context),
          ),
        ],
      ),
    );
  }
}
