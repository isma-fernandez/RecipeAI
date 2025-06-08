import 'package:flutter/material.dart';

/// Notificador per activar/desactivar el mode d’alt contrast
class HighContrastNotifier extends ChangeNotifier {
  bool _highContrast;
  HighContrastNotifier(this._highContrast);

  bool get highContrast => _highContrast;

  void setHighContrast(bool value) {
    _highContrast = value;
    notifyListeners(); // Actualitza els widgets que depenen del contrast
  }
}
