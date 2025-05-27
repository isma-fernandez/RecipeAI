// lib/models/recipe.dart
class Recipe {
  final String id;               // id de Firestore
  final String title;            // nombre_receta
  final int numberOfPeople;      // personas
  final int duration;            // tiempo_total en minutos
  final String imageUrl;         // imagen del plato
  final List<String> ingredients;
  final List<String> steps;      // pasos_con_tiempo (formato "Paso - 5 min")
  int likes;

  Recipe({
    required this.id,
    required this.title,
    required this.numberOfPeople,
    required this.duration,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
    this.likes = 0,
  });

  /// Construye el objeto desde Firestore
  factory Recipe.fromJson(Map<String, dynamic> json, String id) => Recipe(
    id: id,
    title: json['nombre_receta'] as String,
    numberOfPeople: (json['personas'] as num).toInt(),
    duration: (json['tiempo_total'] as num).toInt(),
    imageUrl: json['imagen'] as String,
    ingredients:
    List<String>.from(json['ingredientes'] as List<dynamic>),
    steps: List<String>.from(json['pasos_con_tiempo'] as List<dynamic>),
    likes: (json['likes'] ?? 0) as int,
  );

  /// Para escribir en Firestore
  Map<String, dynamic> toJson() => {
    'nombre_receta': title,
    'personas': numberOfPeople,
    'tiempo_total': duration,
    'imagen': imageUrl,
    'ingredientes': ingredients,
    'pasos_con_tiempo': steps,
    'likes': likes,
  };
}
