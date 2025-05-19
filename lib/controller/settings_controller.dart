import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  // ───────────── CAMPOS (privados) ─────────────
  bool _darkMode           = true;
  bool _highContrast       = false;
  bool _reduceMotion       = false;
  bool _pushNotifications  = true;
  bool _cookingReminders   = false;
  bool _useMobileData      = true;
  bool _autoUploadPhotos   = false;
  double _fontScale        = 1.0;
  String _language         = 'Español';
  Color _accentColor       = Colors.blueAccent;

  // ───────────── GETTERS públicos ─────────────
  bool   get darkMode          => _darkMode;
  bool   get highContrast      => _highContrast;
  bool   get reduceMotion      => _reduceMotion;
  bool   get pushNotifications => _pushNotifications;
  bool   get cookingReminders  => _cookingReminders;
  bool   get useMobileData     => _useMobileData;
  bool   get autoUploadPhotos  => _autoUploadPhotos;
  double get fontScale         => _fontScale;
  String get language          => _language;
  Color  get accentColor       => _accentColor;

  // ───────────── CARGAR ajustes al inicio ─────────────
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _darkMode          = sp.getBool('darkMode')          ?? _darkMode;
    _highContrast      = sp.getBool('highContrast')      ?? _highContrast;
    _reduceMotion      = sp.getBool('reduceMotion')      ?? _reduceMotion;
    _pushNotifications = sp.getBool('pushNotifications') ?? _pushNotifications;
    _cookingReminders  = sp.getBool('cookingReminders')  ?? _cookingReminders;
    _useMobileData     = sp.getBool('useMobileData')     ?? _useMobileData;
    _autoUploadPhotos  = sp.getBool('autoUploadPhotos')  ?? _autoUploadPhotos;
    _fontScale         = sp.getDouble('fontScale')       ?? _fontScale;
    _language          = sp.getString('language')        ?? _language;
    _accentColor       = Color(sp.getInt('accentColor') ?? _accentColor.value);
    notifyListeners();
  }

  // ───────────── SETTERS (persisten y notifican) ─────────────
  Future<void> setDarkMode(bool v)          => _set('darkMode',          v, () => _darkMode = v);
  Future<void> setHighContrast(bool v)      => _set('highContrast',      v, () => _highContrast = v);
  Future<void> setReduceMotion(bool v)      => _set('reduceMotion',      v, () => _reduceMotion = v);
  Future<void> setPushNotifications(bool v) => _set('pushNotifications', v, () => _pushNotifications = v);
  Future<void> setCookingReminders(bool v)  => _set('cookingReminders',  v, () => _cookingReminders = v);
  Future<void> setUseMobileData(bool v)     => _set('useMobileData',     v, () => _useMobileData = v);
  Future<void> setAutoUploadPhotos(bool v)  => _set('autoUploadPhotos',  v, () => _autoUploadPhotos = v);

  Future<void> setFontScale(double v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble('fontScale', v);
    _fontScale = v;
    notifyListeners();
  }

  Future<void> setLanguage(String v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('language', v);
    _language = v;
    notifyListeners();
  }

  Future<void> setAccentColor(Color c) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('accentColor', c.value);
    _accentColor = c;
    notifyListeners();
  }

  // ───────────── helper genérico ─────────────
  Future<void> _set(String key, bool value, VoidCallback assign) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(key, value);
    assign();
    notifyListeners();
  }
}
