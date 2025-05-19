import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // == ESTADO LOCAL (temporal) ==
  bool darkMode = true;
  bool highContrast = false;
  bool reduceMotion = false;
  bool pushNotifications = true;
  bool cookingReminders = false;
  bool useMobileData = true;
  bool autoUploadPhotos = false;
  double fontScale = 1.0;            // 0.8–1.4
  String language = 'Español';       // Español, English…
  Color accentColor = Colors.blueAccent;

  // ==================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
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
              options: const ['Español', 'English', 'Català', 'Français'],
              selected: language,
              onSelected: (v) => setState(() => language = v),
            ),
          ),
          _buildSectionTitle('Apariencia'),
          SwitchListTile(
            value: darkMode,
            onChanged: (v) => setState(() => darkMode = v),
            title: const Text('Tema oscuro'),
            secondary: const Icon(Icons.dark_mode),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Color de acento'),
            subtitle: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
            ),
            onTap: () => _showColorPicker(),
          ),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('Tamaño de fuente'),
            subtitle: Slider(
              value: fontScale,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              label: '${(fontScale * 100).round()} %',
              onChanged: (v) => setState(() => fontScale = v),
            ),
          ),

          _buildSectionTitle('Accesibilidad'),
          SwitchListTile(
            value: highContrast,
            onChanged: (v) => setState(() => highContrast = v),
            title: const Text('Alto contraste'),
            secondary: const Icon(Icons.contrast),
          ),
          SwitchListTile(
            value: reduceMotion,
            onChanged: (v) => setState(() => reduceMotion = v),
            title: const Text('Reducir animaciones'),
            secondary: const Icon(Icons.motion_photos_off),
          ),

          _buildSectionTitle('Notificaciones'),
          SwitchListTile(
            value: pushNotifications,
            onChanged: (v) => setState(() => pushNotifications = v),
            title: const Text('Notificaciones push'),
            secondary: const Icon(Icons.notifications),
          ),
          SwitchListTile(
            value: cookingReminders,
            onChanged: (v) => setState(() => cookingReminders = v),
            title: const Text('Recordatorios de cocción'),
            subtitle: const Text('Recibe avisos cuando termine el tiempo de horno'),
            secondary: const Icon(Icons.timer),
          ),

          _buildSectionTitle('Datos y almacenamiento'),
          SwitchListTile(
            value: useMobileData,
            onChanged: (v) => setState(() => useMobileData = v),
            title: const Text('Usar datos móviles'),
            secondary: const Icon(Icons.signal_cellular_alt),
          ),
          SwitchListTile(
            value: autoUploadPhotos,
            onChanged: (v) => setState(() => autoUploadPhotos = v),
            title: const Text('Subir fotos automáticamente'),
            subtitle: const Text('Se enviarán a la nube para analizar ingredientes'),
            secondary: const Icon(Icons.cloud_upload_outlined),
          ),

          _buildSectionTitle('Acerca de'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versión'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Términos y privacidad'),
            onTap: () {
              // Navega o abre un WebView cuando tengas los documentos legales.
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_rate_outlined),
            title: const Text('Dejar valoración'),
            onTap: () {
              // link a App Store / Google Play
            },
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
        style:
        Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
  );

  /// Diálogo de selección simple (idioma, unidades…)
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

  /// Selector muy sencillo de color de acento
  Future<void> _showColorPicker() async {
    final colors = [
      Colors.blueAccent,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.tealAccent,
    ];

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
              onTap: () {
                setState(() => accentColor = c);
                Navigator.of(context).pop();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c == accentColor ? Colors.white : Colors.transparent,
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
