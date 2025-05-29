import 'package:flutter/material.dart';

class FontScaleNotifier extends ChangeNotifier {
  double _fontScale;

  FontScaleNotifier(this._fontScale);

  double get fontScale => _fontScale;

  void setFontScale(double value) {
    _fontScale = value;
    notifyListeners();
  }
}
