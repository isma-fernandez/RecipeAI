import 'package:flutter/material.dart';

class ReduceMotionNotifier extends ChangeNotifier {
  bool _reduceMotion;

  ReduceMotionNotifier(this._reduceMotion);

  bool get reduceMotion => _reduceMotion;

  void setReduceMotion(bool value) {
    _reduceMotion = value;
    notifyListeners();
  }
}
