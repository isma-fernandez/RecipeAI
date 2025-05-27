import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:recipeai/screens/recipe_detail_screen.dart';

import '../model/recipe.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late Future<void> _initializeControllerFuture;
  late CameraController _controller;
  XFile? _capturedFile;

  bool _isProcessing = false;
  Recipe? _recipeResult;             // receta recibida

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final backCam = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _controller = CameraController(
      backCam,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ───────────────────────── FOTO + BACKEND ──────────────────────────

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final file = await _controller.takePicture();

      // Guarda una copia temporal
      final dir = await getTemporaryDirectory();
      final localPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await file.saveTo(localPath);
      final localFile = XFile(localPath);

      setState(() {
        _capturedFile = localFile;
        _isProcessing = true;
      });

      // Sube a Storage y obtén URI
      final gcsUri = await _uploadToStorage(localFile);

      //Pide la receta (la Cloud Function evita duplicados y/o los devuelve)
      final json = await _callGenRecipe(gcsUri);

      //Convierte a modelo
      final recipe = Recipe.fromJson(json, json['id'] as String);

      // navega directamente al detalle
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(recipe: recipe),
            ),
          );


      setState(() {
        _recipeResult = recipe;
        _isProcessing = false;
      });

      // quitar
      _showRecipeDialog(recipe);
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// Subir la foto
  Future<String> _uploadToStorage(XFile file) async {
    // Usa un nombre único
    final ref = FirebaseStorage.instance
        .ref()
        .child('photos')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(File(file.path));
    return 'gs://${ref.bucket}/${ref.fullPath}';
  }

  /// Llama a la Cloud Function genRecipe y devuelve el JSON de receta
  Future<Map<String, dynamic>> _callGenRecipe(String gcsUri) async {
    final callable = FirebaseFunctions.instance.httpsCallable('genRecipe');
    final result = await callable.call(<String, dynamic>{'gcsUri': gcsUri});
    // La función ya guarda/lee de Firestore y añade el documentId como 'id'
    return Map<String, dynamic>.from(result.data as Map);
  }

  // ──────────────────────────── UI ──────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              Positioned.fill(child: CameraPreview(_controller)),

              // Botón disparo
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: _isProcessing ? null : _takePicture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                    ),
                  ),
                ),
              ),

              // Miniatura de foto capturada (debug)
              if (_capturedFile != null)
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => _showPreview(context, _capturedFile!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_capturedFile!.path),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

              // Overlay de carga
              if (_isProcessing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showPreview(BuildContext context, XFile file) {
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

  void _showRecipeDialog(Recipe recipe) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(recipe.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(recipe.imageUrl),
              const SizedBox(height: 8),
              Text('Personas: ${recipe.numberOfPeople}'),
              Text('Tiempo total: ${recipe.duration} min'),
              const SizedBox(height: 8),
              const Text('Ingredientes:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...recipe.ingredients.map(Text.new),
              const SizedBox(height: 8),
              const Text('Pasos:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...recipe.steps.map(Text.new),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
