import 'package:flutter/material.dart';

/// Notificador per gestionar l’escala de lletra de l’app
class FontScaleNotifier extends ChangeNotifier {
  double _fontScale;
  FontScaleNotifier(this._fontScale);

  double get fontScale => _fontScale;

  void setFontScale(double v) {
    _fontScale = v;
    notifyListeners(); // 🔄 Notifica els widgets que escolten
  }
}
