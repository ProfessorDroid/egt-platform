import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../providers/locale_providers.dart';

/// Language selection. Punjabi/Hindi are untranslated stubs that fall back
/// to English per-key until native review — the screen says so honestly via
/// the system option.
///
/// Language names below are CLDR autonyms (each language's name in itself),
/// which is the platform convention for language pickers — they are proper
/// nouns, not localizable UI copy.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountLanguage)),
      body: ListView(
        children: [
          for (final entry in [
            (null, l10n.languageSystem),
            ('en', 'English'),
            ('pa', 'ਪੰਜਾਬੀ (${l10n.languageComingSoon})'),
            ('hi', 'हिन्दी (${l10n.languageComingSoon})'),
          ])
            RadioListTile<String?>(
              title: Text(entry.$2),
              value: entry.$1,
              groupValue: current?.languageCode,
              onChanged: (v) => ref
                  .read(localeProvider.notifier)
                  .set(v == null ? null : Locale(v)),
            ),
        ],
      ),
    );
  }
}
