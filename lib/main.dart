import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/recipes_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/history_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/popular_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user_screen.dart';
import 'screens/settings_screen.dart';
import 'font_scale_notifier.dart';
import 'accent_color_notifier.dart';
import 'high_contrast_notifier.dart';
import 'reduce_motion_notifier.dart';

// Tema global configurable
class ThemeNotifier extends ChangeNotifier {
  bool _darkMode;
  ThemeNotifier(this._darkMode);
  bool get darkMode => _darkMode;
  ThemeData get themeData => _darkMode ? ThemeData.dark() : ThemeData.light();
  void setDarkMode(bool value) {
    _darkMode = value;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkMode') ?? true;
  final fontScale = prefs.getDouble('fontScale') ?? 1.0;
  final accentColor = Color(prefs.getInt('accentColor') ?? Colors.blueAccent.value);
  final highContrast = prefs.getBool('highContrast') ?? false;
  final reduceMotion = prefs.getBool('reduceMotion') ?? false;

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => ThemeNotifier(isDark)),
    ChangeNotifierProvider(create: (_) => FontScaleNotifier(fontScale)),
    ChangeNotifierProvider(create: (_) => AccentColorNotifier(accentColor)),
    ChangeNotifierProvider(create: (_) => HighContrastNotifier(highContrast)),
    ChangeNotifierProvider(create: (_) => ReduceMotionNotifier(reduceMotion)),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer4<ThemeNotifier, FontScaleNotifier, AccentColorNotifier, HighContrastNotifier>(
      builder: (context, theme, fontScale, accent, highContrast, child) {
        ThemeData baseTheme = theme.themeData;

        // Si el mode d’alt contrast està activat, personalitza el tema
        if (highContrast.highContrast) {
          baseTheme = baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              background: theme.darkMode ? Colors.black : Colors.white,
              onBackground: theme.darkMode ? Colors.yellowAccent : Colors.black,
              primary: theme.darkMode ? Colors.white : Colors.black,
              secondary: Colors.yellowAccent,
              surface: theme.darkMode ? Colors.black : Colors.white,
              onSurface: theme.darkMode ? Colors.yellowAccent : Colors.black,
            ),
            textTheme: baseTheme.textTheme.copyWith(
              bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.darkMode ? Colors.yellowAccent : Colors.black),
              bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.darkMode ? Colors.yellowAccent : Colors.black),
              titleLarge: baseTheme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.darkMode ? Colors.yellowAccent : Colors.black),
            ),
            switchTheme: baseTheme.switchTheme.copyWith(
              thumbColor: MaterialStateProperty.all(Colors.yellowAccent),
              trackColor: MaterialStateProperty.all(theme.darkMode ? Colors.black87 : Colors.grey[300]),
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'RecipeAI App',
          theme: baseTheme.copyWith(
            scaffoldBackgroundColor: theme.darkMode ? Colors.black : Colors.white,
            primaryColor: theme.darkMode ? Colors.white : Colors.black,
            colorScheme: baseTheme.colorScheme.copyWith(secondary: accent.accentColor),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: fontScale.fontScale),
            child: child!,
          ),
          home: const RootPage(),
        );
      },
    );
  }
}

// Gestor de navegació principal amb BottomNavigationBar
class RootPage extends StatefulWidget {
  const RootPage({super.key});
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted && user != null) {
        setState(() => _currentIndex = 1); // Entra a "Populars" si inicia sessió
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;

    // Definició de pantalles segons si l’usuari ha iniciat sessió
    final pages = [
      const IniciScreen(),
      const PopularScreen(),
      const CameraScreen(),
      if (loggedIn) const HistoryScreen(),
      if (loggedIn) const FavoritesScreen(),
      if (loggedIn) const ProfileScreen() else const LoginScreen(),
      const SettingsScreen(),
    ];

    // Ítems del menú inferior
    final items = [
      const BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Inici'),
      const BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Populars'),
      const BottomNavigationBarItem(icon: Icon(Icons.photo_camera), label: 'Escanejar'),
      if (loggedIn) const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
      if (loggedIn) const BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorits'),
      BottomNavigationBarItem(icon: Icon(loggedIn ? Icons.account_circle : Icons.login), label: loggedIn ? 'Perfil' : 'Login'),
      const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Configuració'),
    ];

    _currentIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Provider.of<AccentColorNotifier>(context).accentColor,
        unselectedItemColor: Colors.grey,
        items: items,
      ),
    );
  }
}
