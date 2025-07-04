// lib/models/recipe.dart
class Recipe {
  final String id;               // id de Firestore
  final String title;            // nombre_receta
  final int numberOfPeople;      // personas
  final int duration;            // tiempo_total
  final String imageUrl;         // imagen
  final List<String> ingredients;
  final List<String> steps;      // pasos_con_tiempo
  final List<String> alergenos;
  int likes;

  Recipe({
    required this.id,
    required this.title,
    required this.numberOfPeople,
    required this.duration,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
    required this.alergenos,
    this.likes = 0,
  });

  /// Construir desde Firestore
  factory Recipe.fromJson(Map<String, dynamic> json, String id) => Recipe(
    id: id,
    title: (json['nombre_receta'] ?? '') as String,
    numberOfPeople: (json['personas'] ?? 1) as int,
    duration: (json['tiempo_total'] ?? 0) as int,
    imageUrl: (json['imagen'] ?? '') as String,
    ingredients: (json['ingredientes'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    steps: (json['pasos_con_tiempo'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    alergenos: (json['alergenos'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    likes: (json['likes'] ?? 0) as int,
  );

  /// Convertir a Firestore
  Map<String, dynamic> toJson() => {
    'nombre_receta': title,
    'personas': numberOfPeople,
    'tiempo_total': duration,
    'imagen': imageUrl,
    'ingredientes': ingredients,
    'pasos_con_tiempo': steps,
    'alergenos': alergenos,
    'likes': likes,
  };
}
