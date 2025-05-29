import 'package:flutter/material.dart';

class HighContrastNotifier extends ChangeNotifier {
  bool _highContrast;
  HighContrastNotifier(this._highContrast);

  bool get highContrast => _highContrast;

  void setHighContrast(bool value) {
    _highContrast = value;
    notifyListeners();
  }
}
