import 'package:flutter/material.dart';

/// Notificador per gestionar el color d'accent de l'app
class AccentColorNotifier extends ChangeNotifier {
  Color _accentColor;
  AccentColorNotifier(this._accentColor);

  Color get accentColor => _accentColor;

  void setAccentColor(Color c) {
    _accentColor = c;
    notifyListeners(); // 🔄 Notifica els widgets que escolten
  }
}
