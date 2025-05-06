import 'package:flutter/material.dart';
import '../model/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const RecipeCard({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Cover image
          Positioned.fill(
            child: Image.network(
              recipe.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          // Top‑>bottom gradient overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Title — top‑left
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Text(
              recipe.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
            ),
          ),
          // Servings & duration — bottom‑left
          Positioned(
            bottom: 8,
            left: 12,
            child: Row(
              children: [
                const Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Text('${recipe.numberOfPeople}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 12),
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 4),
                Text('${recipe.duration} min', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}