import 'package:flutter/material.dart';

// Notificador per controlar si l'usuari prefereix reduir animacions
class ReduceMotionNotifier extends ChangeNotifier {
  bool _reduceMotion;
  ReduceMotionNotifier(this._reduceMotion);

  bool get reduceMotion => _reduceMotion;

  void setReduceMotion(bool value) {
    _reduceMotion = value;
    notifyListeners(); // Notifica els widgets que depenen d'aquest valor
  }
}
