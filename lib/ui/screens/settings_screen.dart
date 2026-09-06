import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../logic/providers.dart';
import '../../models/settings.dart';
import '../highlight_colors.dart';

/// Settings page: error limit on/off (with the limit itself), whether wrong
/// entries are visually marked, highlighting on/off, sound, theme and
/// language.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l10n.errorLimitTitle),
            subtitle: Text(l10n.errorLimitSubtitle),
            value: settings.errorLimitEnabled,
            onChanged: controller.setErrorLimitEnabled,
          ),
          if (settings.errorLimitEnabled)
            ListTile(
              title: Text(l10n.maxMistakesTitle),
              subtitle: Slider(
                value: settings.maxMistakes.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '${settings.maxMistakes}',
                onChanged: (value) => controller.setMaxMistakes(value.round()),
              ),
            ),
          SwitchListTile(
            title: Text(l10n.showErrorsTitle),
            subtitle: Text(l10n.showErrorsSubtitle),
            value: settings.showErrors,
            onChanged: controller.setShowErrors,
          ),
          SwitchListTile(
            title: Text(l10n.highlightsTitle),
            subtitle: Text(l10n.highlightsSubtitle),
            value: settings.highlightEnabled,
            onChanged: controller.setHighlightEnabled,
          ),
          ListTile(
            title: Text(l10n.highlightColorTitle),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 12,
                children: [
                  for (final color in HighlightColor.values)
                    _HighlightColorSwatch(
                      color: color,
                      selected: settings.highlightColor == color,
                      onTap: () => controller.setHighlightColor(color),
                    ),
                ],
              ),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.soundTitle),
            subtitle: Text(l10n.soundSubtitle),
            value: settings.soundEnabled,
            onChanged: controller.setSoundEnabled,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l10n.designHeading, style: Theme.of(context).textTheme.titleMedium),
          ),
          RadioGroup<AppThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (value) => controller.setThemeMode(value!),
            child: Column(
              children: [
                RadioListTile<AppThemeMode>(title: Text(l10n.themeSystem), value: AppThemeMode.system),
                RadioListTile<AppThemeMode>(title: Text(l10n.themeLight), value: AppThemeMode.light),
                RadioListTile<AppThemeMode>(title: Text(l10n.themeDark), value: AppThemeMode.dark),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l10n.languageHeading, style: Theme.of(context).textTheme.titleMedium),
          ),
          RadioGroup<AppLocale>(
            groupValue: settings.locale,
            onChanged: (value) => controller.setLocale(value!),
            child: Column(
              children: [
                RadioListTile<AppLocale>(title: Text(l10n.languageSystem), value: AppLocale.system),
                RadioListTile<AppLocale>(title: Text(l10n.languageGerman), value: AppLocale.de),
                RadioListTile<AppLocale>(title: Text(l10n.languageEnglish), value: AppLocale.en),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One tappable color circle in the highlight-color picker; shows a check
/// mark when it is the current selection.
class _HighlightColorSwatch extends StatelessWidget {
  final HighlightColor color;
  final bool selected;
  final VoidCallback onTap;

  const _HighlightColorSwatch({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: color.label(l10n),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.swatch,
            border: selected
                ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2)
                : null,
          ),
          alignment: Alignment.center,
          child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
        ),
      ),
    );
  }
}
