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

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late Future<void> _initializeControllerFuture;
  late CameraController _controller;
  XFile? _previewFile;
  bool _isProcessing = false;

  /* alérgenos del usuario */
  Set<String> _userAllergens = {};

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadUserAllergens();
  }

  Future<void> _loadUserAllergens() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final list = snap.data()?['allergies'] as List<dynamic>? ?? [];
    _userAllergens = list.map((e) => e.toString()).toSet();
  }

  Future<void> _initializeCamera() async {
    final cams = await availableCameras();
    final back = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cams.first,
    );
    _controller =
        CameraController(back, ResolutionPreset.medium, enableAudio: false);
    _initializeControllerFuture = _controller.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /* ────────── captura o galería ────────── */

  Future<void> _shoot() async {
    await _initializeControllerFuture;
    final raw = await _controller.takePicture();
    await _handleSelectedFile(raw);
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) await _handleSelectedFile(picked);
  }

  Future<void> _handleSelectedFile(XFile raw) async {
    setState(() {
      _previewFile = raw;
      _isProcessing = true;
    });

    try {
      final tmpDir = await getTemporaryDirectory();
      final tmpPath =
          '${tmpDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await raw.saveTo(tmpPath);
      final local = XFile(tmpPath);

      final gcsUri = await _uploadToStorage(local);
      final json = await _callGenRecipe(gcsUri);
      final recipe = Recipe.fromJson(json, json['id'] as String);

      /* aviso de alérgenos */
      if (_userAllergens.isNotEmpty &&
          recipe.alergenos.any(_userAllergens.contains)) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Atenció'),
              content: Text(
                'Aquesta recepta conté algun dels teus al·lèrgens:\n'
                    '${recipe.alergenos.where(_userAllergens.contains).join(', ')}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }

      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('history')
          .add({
        'name': recipe.title,
        'imageUrl': recipe.imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /* ────────── backend ────────── */

  Future<String> _uploadToStorage(XFile file) async {
    final ref = FirebaseStorage.instance
        .ref('photos/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(File(file.path));
    return 'gs://${ref.bucket}/${ref.fullPath}';
  }

  Future<Map<String, dynamic>> _callGenRecipe(String gcsUri) async {
    final functions = FirebaseFunctions.instanceFor(region: 'europe-west2');
    final callable = functions.httpsCallable(
      'genRecipe',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 4)),
    );
    final result = await callable.call({'gcsUri': gcsUri});
    return Map<String, dynamic>.from(result.data as Map);
  }

  /* ────────── UI ────────── */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              Positioned.fill(child: CameraPreview(_controller)),
              Positioned(
                bottom: 40,
                left: MediaQuery.of(context).size.width * .2,
                child: _CircleButton(
                  icon: Icons.camera_alt,
                  onTap: _isProcessing ? null : _shoot,
                ),
              ),
              Positioned(
                bottom: 40,
                right: MediaQuery.of(context).size.width * .2,
                child: _CircleButton(
                  icon: Icons.photo_library,
                  onTap: _isProcessing ? null : _pickFromGallery,
                ),
              ),
              if (_previewFile != null)
                Positioned(
                  top: 40,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => _showPreview(_previewFile!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(_previewFile!.path),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              if (_isProcessing)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black45,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showPreview(XFile file) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Image.file(File(file.path), fit: BoxFit.contain),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ────────── botón redondo ────────── */
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 4, color: Colors.white),
          color: Colors.black54,
        ),
        child: Icon(icon, size: 32, color: Colors.white),
      ),
    );
  }
}
