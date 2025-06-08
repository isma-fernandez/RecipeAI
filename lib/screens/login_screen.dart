import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // clau per validar el formulari
  final _emailCtrl = TextEditingController(); // controlador de l’email
  final _pwdCtrl = TextEditingController(); // controlador de la contrasenya
  bool _obscure = true; // mostrar o amagar la contrasenya

  @override
  void dispose() {
    _emailCtrl.dispose(); _pwdCtrl.dispose(); super.dispose();
  }

  // intenta iniciar sessió amb les credencials donades
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text.trim(),
      );
      // sessió iniciada correctament → avís
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesión iniciada correctamente')));
    } on FirebaseAuthException catch (e) {
      // gestió d’errors comuns de Firebase Auth
      String msg;
      switch (e.code) {
        case 'invalid-credential': msg = 'Credenciales inválidas. Verifica tu correo y contraseña.'; break;
        case 'user-not-found': msg = 'No existe ningún usuario con ese correo.'; break;
        case 'wrong-password': msg = 'Contraseña incorrecta.'; break;
        default: msg = 'Error inesperado: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 32),
              // icona + títol de l’app
              Icon(Icons.menu_book, size: 72, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 24),
              Text('RecipeAI', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 48),
              // input de correu electrònic
              TextFormField(
                controller: _emailCtrl,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.mail_outline)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Introduce tu correo';
                  final regex = RegExp(r'.+@.+\..+');
                  if (!regex.hasMatch(v)) return 'Formato no válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // input de contrasenya amb opció d’amagar/mostrar
              TextFormField(
                controller: _pwdCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 32),
              // botó per iniciar sessió
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Entrar'),
                  ),
                ),
              ),
              // enllaços auxiliars: recuperar contrasenya o registrar-se
              TextButton(
                onPressed: () {
                  // funcionalitat pendent: reset contrasenya
                },
                child: const Text('¿Has olvidado la contraseña?'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: const Text("¿No tienes cuenta? Regístrate"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
