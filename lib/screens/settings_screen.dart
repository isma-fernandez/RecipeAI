import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../font_scale_notifier.dart';
import '../main.dart'; // Per ThemeNotifier
import '../accent_color_notifier.dart';
import '../high_contrast_notifier.dart';
import '../reduce_motion_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = true;
  double fontScale = 1.0;
  String language = 'Español';
  Color accentColor = Colors.blueAccent;
  bool highContrast = false;
  bool reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? true;
      fontScale = prefs.getDouble('fontScale') ?? 1.0;
      language = prefs.getString('language') ?? 'Español';
      accentColor = Color(prefs.getInt('accentColor') ?? Colors.blueAccent.value);
      highContrast = prefs.getBool('highContrast') ?? false;
      reduceMotion = prefs.getBool('reduceMotion') ?? false;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) prefs.setBool(key, value);
    if (value is String) prefs.setString(key, value);
    if (value is double) prefs.setDouble(key, value);
    if (value is int) prefs.setInt(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuració'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionTitle('General'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Idioma'),
            subtitle: Text(language),
            onTap: () => _showOptionsDialog(
              title: 'Selecciona idioma',
              options: const ['Català'],
              selected: language,
              onSelected: (v) async {
                setState(() => language = v);
                await _savePreference('language', v);
                // Aquí pots afegir la lògica de canvi d'idioma global
              },
            ),
          ),
          _buildSectionTitle('Aparença'),
          SwitchListTile(
            value: darkMode,
            onChanged: (v) async {
              setState(() => darkMode = v);
              await _savePreference('darkMode', v);
              Provider.of<ThemeNotifier>(context, listen: false).setDarkMode(v);
            },
            title: const Text('Tema fosc'),
            secondary: const Icon(Icons.dark_mode),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Color d’accent'),
            subtitle: Consumer<AccentColorNotifier>(
              builder: (context, accentNotifier, _) => Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: accentNotifier.accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
              ),
            ),
            onTap: () => _showColorPicker(context),
          ),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('Mida de lletra'),
            subtitle: Slider(
              value: fontScale,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              label: '${(fontScale * 100).round()} %',
              onChanged: (v) {
                setState(() => fontScale = v);
                _savePreference('fontScale', v);
                Provider.of<FontScaleNotifier>(context, listen: false).setFontScale(v);
              },
            ),
          ),
          _buildSectionTitle('Accessibilitat'),
          Consumer<HighContrastNotifier>(
            builder: (context, highContrastNotifier, _) => SwitchListTile(
              value: highContrastNotifier.highContrast,
              onChanged: (v) async {
                highContrastNotifier.setHighContrast(v);
                await _savePreference('highContrast', v);
              },
              title: const Text('Alt contrast'),
              secondary: const Icon(Icons.contrast),
            ),
          ),
          Consumer<ReduceMotionNotifier>(
            builder: (context, reduceMotionNotifier, _) => SwitchListTile(
              value: reduceMotionNotifier.reduceMotion,
              onChanged: (v) async {
                reduceMotionNotifier.setReduceMotion(v);
                await _savePreference('reduceMotion', v);
              },
              title: const Text('Reduir animacions'),
              secondary: const Icon(Icons.motion_photos_off),
            ),
          ),
          _buildSectionTitle('Sobre l’app'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versió'),
            subtitle: const Text('1.0.0'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ======== HELPERS =================================================

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold)),
  );

  Future<void> _showOptionsDialog({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (opt) => RadioListTile<String>(
              value: opt,
              groupValue: selected,
              onChanged: (v) {
                if (v != null) onSelected(v);
                Navigator.of(context).pop();
              },
              title: Text(opt),
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _showColorPicker(BuildContext context) async {
    final colors = [
      Colors.blueAccent,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.tealAccent,
    ];
    final accentNotifier = Provider.of<AccentColorNotifier>(context, listen: false);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: colors
              .map(
                (c) => GestureDetector(
              onTap: () async {
                setState(() => accentColor = c);
                accentNotifier.setAccentColor(c);
                await _savePreference('accentColor', c.value);
                Navigator.of(context).pop();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c == accentNotifier.accentColor
                        ? Colors.white
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}
