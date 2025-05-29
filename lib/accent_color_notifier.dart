import 'package:flutter/material.dart';

class AccentColorNotifier extends ChangeNotifier {
  Color _accentColor;
  AccentColorNotifier(this._accentColor);

  Color get accentColor => _accentColor;

  void setAccentColor(Color c) {
    _accentColor = c;
    notifyListeners();
  }
}
