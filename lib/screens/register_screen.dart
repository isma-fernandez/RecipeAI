import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl   = TextEditingController();
  final _repPwdCtrl= TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _repPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final login = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text.trim(),
      );
      const defaultFoto =
          'https://storage.googleapis.com/airecipe-user-photos/default.png';
      final uid = login.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name'      : _nameCtrl.text.trim(),
        'photoUrl'  : defaultFoto,
        'allergies' : '',
        'createdAt' : FieldValue.serverTimestamp(),
        'updatedAt' : FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();            // vuelve al login
    } on FirebaseAuthException catch (e) {
      var msg = switch (e.code) {
        'email-already-in-use' => 'Este correo ya está en uso',
        'weak-password'        => 'Contraseña demasiado débil',
        'invalid-email'        => 'Correo no válido',
        _                      => 'Error: ${e.message}'
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Crear cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 24),

              // Nombre
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Introduce tu nombre' : null,
              ),
              const SizedBox(height: 16),

              // Email
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

              // Contraseña
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
                validator: (v) =>
                (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 16),

              // Repetir contraseña
              TextFormField(
                controller: _repPwdCtrl,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'Repite la contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) => (v != _pwdCtrl.text) ? 'No coincide' : null,
              ),
              const SizedBox(height: 32),

              // Botón Crear cuent
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Registrarse'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
