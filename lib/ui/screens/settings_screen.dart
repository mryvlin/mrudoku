import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/providers.dart';
import '../../models/settings.dart';
import '../highlight_colors.dart';

/// Settings page: error limit on/off (with the limit itself), whether wrong
/// entries are visually marked, highlighting on/off, sound, and theme.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Fehlerlimit aktiv'),
            subtitle: const Text('Spiel endet nach zu vielen Fehlern'),
            value: settings.errorLimitEnabled,
            onChanged: controller.setErrorLimitEnabled,
          ),
          if (settings.errorLimitEnabled)
            ListTile(
              title: const Text('Maximale Fehler'),
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
            title: const Text('Falsche Zahlen anzeigen'),
            subtitle: const Text('Markiert falsch eingetragene Zahlen farblich'),
            value: settings.showErrors,
            onChanged: controller.setShowErrors,
          ),
          SwitchListTile(
            title: const Text('Hervorhebungen'),
            subtitle: const Text('Zeile/Spalte/Box und gleiche Zahlen farblich markieren'),
            value: settings.highlightEnabled,
            onChanged: controller.setHighlightEnabled,
          ),
          ListTile(
            title: const Text('Hervorhebungsfarbe'),
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
            title: const Text('Sound'),
            subtitle: const Text('Feedback-Töne und Vibration bei Eingaben'),
            value: settings.soundEnabled,
            onChanged: controller.setSoundEnabled,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text('Design', style: Theme.of(context).textTheme.titleMedium),
          ),
          RadioGroup<AppThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (value) => controller.setThemeMode(value!),
            child: const Column(
              children: [
                RadioListTile<AppThemeMode>(title: Text('System'), value: AppThemeMode.system),
                RadioListTile<AppThemeMode>(title: Text('Hell'), value: AppThemeMode.light),
                RadioListTile<AppThemeMode>(title: Text('Dunkel'), value: AppThemeMode.dark),
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
    return Tooltip(
      message: color.label,
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
