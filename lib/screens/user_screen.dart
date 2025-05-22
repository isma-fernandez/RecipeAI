// /screens/profile_screen.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  //  Ajustes del bucket y la imagen por defecto
  static const _bucketUrl = 'gs://airecipe-user-photos';
  static const _defaultAvatar =
      'https://storage.googleapis.com/airecipe-user-photos/default.png';

  // Instancia de Firebase Storage
  final FirebaseStorage _bucket = FirebaseStorage.instanceFor(bucket: _bucketUrl);

  final _formKey = GlobalKey<FormState>();
  final _allergyCtrl = TextEditingController();

  bool _uploading = false;
  String? _photoUrl;

  User get _user => FirebaseAuth.instance.currentUser!;
  late final CollectionReference _users =
  FirebaseFirestore.instance.collection('users');

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final snap = await _users.doc(_user.uid).get();
    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>;
      _photoUrl = data['photoUrl'];                // puede ser null
      _allergyCtrl.text = data['allergies'] ?? '';
    } else {
      // Si el documento NO existe creamos uno con avatar por defecto
      await _users.doc(_user.uid).set({
        'name': _user.displayName ?? '',
        'photoUrl': _defaultAvatar,
        'allergies': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _photoUrl = _defaultAvatar;
    }
    setState(() {});
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
    if (picked == null) return;
    setState(() => _uploading = true);
    final ref = _bucket.ref('avatars/${_user.uid}.jpg');
    await ref.putFile(File(picked.path));
    _photoUrl = await ref.getDownloadURL();

    await _users
        .doc(_user.uid)
        .set({'photoUrl': _photoUrl, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));

    setState(() => _uploading = false);
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _users.doc(_user.uid).set({
      'allergies': _allergyCtrl.text.trim(),
      'photoUrl': _photoUrl ?? _defaultAvatar,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageToShow = _photoUrl ?? _defaultAvatar;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _uploading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(imageToShow),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueAccent,
                          ),
                          child: const Icon(Icons.camera_alt, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                initialValue: _user.displayName,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _user.email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _allergyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alergias (separadas por comas)',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Guardar'),
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
