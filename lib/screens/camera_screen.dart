import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:recipeai/screens/recipe_detail_screen.dart';
import '../model/recipe.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // controlador de la càmera i estat de preparació
  late Future<void> _initializeControllerFuture;
  late CameraController _controller;

  // fitxer previsualitzat i bandera de processament
  XFile? _previewFile;
  bool _isProcessing = false;

  // conjunt d’al·lèrgens del perfil de l’usuari
  Set<String> _userAllergens = {};

  @override
  void initState() {
    super.initState();
    _initializeCamera();       // iniciar càmera
    _loadUserAllergens();      // carregar al·lèrgens de l’usuari
  }

  // carregar els al·lèrgens del perfil de l’usuari des de Firestore
  Future<void> _loadUserAllergens() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final list = snap.data()?['allergies'] as List<dynamic>? ?? [];
    _userAllergens = list.map((e) => e.toString()).toSet();
  }

  // inicialitzar la càmera posterior del dispositiu
  Future<void> _initializeCamera() async {
    final cams = await availableCameras();
    final back = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
    _controller = CameraController(back, ResolutionPreset.medium, enableAudio: false);
    _initializeControllerFuture = _controller.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();  // alliberar recursos de la càmera
    super.dispose();
  }

  /* ────────── captura o galeria ────────── */

  // fer una foto i processar-la
  Future<void> _shoot() async {
    await _initializeControllerFuture;
    final raw = await _controller.takePicture();
    await _handleSelectedFile(raw);
  }

  // seleccionar una imatge de la galeria i processar-la
  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) await _handleSelectedFile(picked);
  }

  // gestionar la imatge: pujar, demanar recepta, mostrar avís i navegar
  Future<void> _handleSelectedFile(XFile raw) async {
    setState(() {
      _previewFile = raw;        // mostrar miniatura
      _isProcessing = true;      // bloquejar botons
    });

    try {
      final tmpDir = await getTemporaryDirectory();
      final tmpPath = '${tmpDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await raw.saveTo(tmpPath);
      final local = XFile(tmpPath);

      // pujar imatge a Storage
      final gcsUri = await _uploadToStorage(local);

      // cridar funció cloud per obtenir la recepta
      final json = await _callGenRecipe(gcsUri);
      final recipe = Recipe.fromJson(json, json['id'] as String);

      // mostrar avís si la recepta conté al·lèrgens personals
      if (_userAllergens.isNotEmpty && recipe.alergenos.any(_userAllergens.contains)) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Atenció'),
              content: Text('Aquesta recepta conté algun dels teus al·lèrgens:\n${recipe.alergenos.where(_userAllergens.contains).join(', ')}'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
            ),
          );
        }
      }

      // afegir recepta a l’historial de l’usuari
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('history').add({
        'name': recipe.title,
        'imageUrl': recipe.imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // obrir pantalla de detall amb la recepta
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)));
    } catch (e) {
      // error de xarxa o resposta → mostrar snack
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /* ────────── backend ────────── */

  // pujar la imatge a Firebase Storage i retornar el gcsUri
  Future<String> _uploadToStorage(XFile file) async {
    final ref = FirebaseStorage.instance.ref('photos/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(File(file.path));
    return 'gs://${ref.bucket}/${ref.fullPath}';
  }

  // cridar a la Cloud Function per generar la recepta
  Future<Map<String, dynamic>> _callGenRecipe(String gcsUri) async {
    final functions = FirebaseFunctions.instanceFor(region: 'europe-west2');
    final callable = functions.httpsCallable('genRecipe', options: HttpsCallableOptions(timeout: const Duration(minutes: 4)));
    final result = await callable.call({'gcsUri': gcsUri});
    return Map<String, dynamic>.from(result.data as Map);
  }

  /* ────────── UI ────────── */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _initializeControllerFuture,  // espera a la càmera
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          return Stack(
            children: [
              // vista de la càmera
              Positioned.fill(child: CameraPreview(_controller)),

              // botó per fer foto
              Positioned(
                bottom: 40,
                left: MediaQuery.of(context).size.width * .2,
                child: _CircleButton(icon: Icons.camera_alt, onTap: _isProcessing ? null : _shoot),
              ),

              // botó per obrir galeria
              Positioned(
                bottom: 40,
                right: MediaQuery.of(context).size.width * .2,
                child: _CircleButton(icon: Icons.photo_library, onTap: _isProcessing ? null : _pickFromGallery),
              ),

              // miniatura de la foto escollida
              if (_previewFile != null)
                Positioned(
                  top: 40,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => _showPreview(_previewFile!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(File(_previewFile!.path), width: 60, height: 60, fit: BoxFit.cover),
                    ),
                  ),
                ),

              // capa de càrrega mentre s’està processant
              if (_isProcessing)
                const Positioned.fill(
                  child: ColoredBox(color: Colors.black45, child: Center(child: CircularProgressIndicator())),
                ),
            ],
          );
        },
      ),
    );
  }

  // vista prèvia en gran de la imatge seleccionada
  void _showPreview(XFile file) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Image.file(File(file.path), fit: BoxFit.contain),
            Positioned(top: 8, right: 8, child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())),
          ],
        ),
      ),
    );
  }
}

/* ────────── botó rodó ────────── */
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(width: 4, color: Colors.white), color: Colors.black54),
        child: Icon(icon, size: 32, color: Colors.white),
      ),
    );
  }
}
