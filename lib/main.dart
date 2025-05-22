import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/recipes_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RecipeAI App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
          primary: Colors.white,
          secondary: Colors.blueAccent,
        ),
      ),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({Key? key}) : super(key: key);
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    // Redibujar si el usuario inicia o cierra sesión
    FirebaseAuth.instance.authStateChanges().listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    // Páginas que se muestran según el estado de sesión
    final pages = [
      const RecipesScreen(),
      const CameraScreen(),
      if (loggedIn) const ProfileScreen() else const LoginScreen(),
      const SettingsScreen(),
    ];

    // Nav
    final items = [
      const BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_rounded), label: 'Receptes'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.photo_camera), label: 'Escanejar'),
      BottomNavigationBarItem(
        icon: Icon(loggedIn ? Icons.account_circle : Icons.login),
        label: loggedIn ? 'Perfil' : 'Login',
      ),
      const BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined), label: 'Configuració'),
    ];

    // Evita índices fuera de rango si cambia el nº de páginas
    _currentIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: items,
      ),
    );
  }
}
