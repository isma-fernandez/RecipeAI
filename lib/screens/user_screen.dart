import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<String> kAllergens = [
    'Gluten','Crustacis','Ous','Peix','Cacauets','Soja','Llet','Fruits de closca','Api',
    'Mostassa','Grans de sèsam','Diòxid de sofre i sulfits','Tramussos','Mol·luscs',
  ];
  static const _bucketUrl = 'gs://airecipe-user-photos';
  static const _defaultAvatar = 'https://storage.googleapis.com/airecipe-user-photos/default.png';

  final FirebaseStorage _bucket = FirebaseStorage.instanceFor(bucket: _bucketUrl);
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  bool _uploading = false;
  String? _photoUrl;
  Set<String> _selectedAllergens = {};
  User get _user => FirebaseAuth.instance.currentUser!;
  late final CollectionReference _users = FirebaseFirestore.instance.collection('users');

  @override
  void initState() {
    super.initState();
    _loadProfile(); // Carrega el perfil de l'usuari
  }

  // Llegeix dades de l'usuari de Firestore
  Future<void> _loadProfile() async {
    final snap = await _users.doc(_user.uid).get();
    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>;
      _photoUrl = data['photoUrl'];
      _selectedAllergens = Set<String>.from(data['allergies'] ?? []);
      _nameCtrl.text = data['name'] ?? _user.displayName ?? '';
    } else {
      await _users.doc(_user.uid).set({
        'name': _user.displayName ?? '',
        'photoUrl': _defaultAvatar,
        'allergies': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _photoUrl = _defaultAvatar;
      _nameCtrl.text = _user.displayName ?? '';
    }
    setState(() {});
  }

  // Puja nova imatge de perfil a Firebase Storage
  Future<void> _pickAndUploadImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 600);
    if (picked == null) return;
    setState(() => _uploading = true);
    final ref = _bucket.ref('avatars/${_user.uid}.jpg');
    await ref.putFile(File(picked.path));
    _photoUrl = await ref.getDownloadURL();
    await _users.doc(_user.uid).set({
      'photoUrl': _photoUrl,
      'updatedAt': FieldValue.serverTimestamp()
    }, SetOptions(merge: true));
    setState(() => _uploading = false);
  }

  // Desa les dades modificades del perfil
  Future<void> _saveProfile() async {
    await _users.doc(_user.uid).set({
      'name': _nameCtrl.text.trim(),
      'allergies': _selectedAllergens.toList(),
      'photoUrl': _photoUrl ?? _defaultAvatar,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado')),
    );
  }

  // Mostra diàleg per seleccionar al·lèrgens
  Future<void> _openAllergenSelector() async {
    final temp = Set<String>.from(_selectedAllergens);
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Selecciona al·lèrgens'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              children: kAllergens.map((a) {
                final checked = temp.contains(a);
                return CheckboxListTile(
                  value: checked,
                  title: Text(a),
                  onChanged: (val) {
                    setStateDialog(() {
                      val == true ? temp.add(a) : temp.remove(a);
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel·lar')),
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedAllergens = temp);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageToShow = _photoUrl ?? _defaultAvatar;

    return Scaffold(
      appBar: AppBar(
        title: const Text('El meu perfil'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut()),
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
              // Avatar amb botó per canviar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(radius: 60, backgroundImage: NetworkImage(imageToShow)),
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
              // Nom de l’usuari
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              // Correu electrònic (no editable)
              TextFormField(
                initialValue: _user.email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Correu',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 16),
              // Llista d’al·lèrgens
              InkWell(
                onTap: _openAllergenSelector,
                child: IgnorePointer(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Al·lèrgens',
                      prefixIcon: Icon(Icons.warning_amber_outlined),
                    ),
                    controller: TextEditingController(
                      text: _selectedAllergens.join(', '),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Botó de guardar
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
