import 'package:flutter/material.dart';
import '../model/recipe.dart';
import '../screens/recipe_detail_screen.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200, // altura mínima para evitar errores de layout
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Imagen o placeholder
              Positioned.fill(
                child: recipe.imageUrl.isNotEmpty
                    ? Image.network(recipe.imageUrl, fit: BoxFit.cover)
                    : Container(
                  color: Colors.grey,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 40),
                  ),
                ),
              ),
              // sombreado para legibilidad
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black54],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Título de la receta
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Text(
                  recipe.title.isNotEmpty ? recipe.title : 'Receta sin nombre',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Personas y duración
              Positioned(
                bottom: 8,
                left: 12,
                child: Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('${recipe.numberOfPeople}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white)),
                    const SizedBox(width: 12),
                    const Icon(Icons.schedule, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('${recipe.duration} min',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
