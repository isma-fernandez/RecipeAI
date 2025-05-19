import 'package:flutter/material.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus(); // cierra teclado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🤖 Sesión iniciada (mock)')),
      );
      // Aquí, cuando toque, llamarás a tu backend o Firebase/GCP…
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
              // Logo / título de la app
              Icon(Icons.menu_book, size: 72, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 24),
              Text('RecipeAI', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 48),

              // === Email ============================
              TextFormField(
                controller: _emailCtrl,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Introduce tu correo';
                  final regex = RegExp(r'.+@.+\..+');
                  if (!regex.hasMatch(v)) return 'Formato no válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // === Contraseña =======================
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
                validator: (v) => (v == null || v.length < 6)
                    ? 'Mínimo 6 caracteres'
                    : null,
              ),
              const SizedBox(height: 32),

              // === Botón de login ===================
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

              // === Links “Olvidé…” y “Crear cuenta” ==
              TextButton(
                onPressed: () {
                  // future: reset de contraseña
                },
                child: const Text('¿Olvidaste la contraseña?'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
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
