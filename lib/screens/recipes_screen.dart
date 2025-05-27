import 'package:flutter/material.dart';
import '../widgets/search_input.dart';
import '../widgets/recipe_card.dart';
import '../model/recipe.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: temporal per mostrar alguna cosa per ara
    final dataFromFirestore = {
      'nombre_receta': 'Tortilla de Patatas',
      'personas': 4,
      'tiempo_total': 45,
      'imagen': 'https://lacocinadefrabisa.lavozdegalicia.es/wp-content/uploads/2019/05/tortilla-espa%C3%B1ola.jpg',
      'ingredientes': [
        '4 huevos',
        '3 patatas medianas',
        '1 cebolla',
        'Aceite de oliva',
        'Sal'
      ],
      'pasos_con_tiempo': [
        'Pelar y cortar las patatas - 10 min',
        'Freír las patatas y cebolla - 15 min',
        'Batir los huevos - 5 min',
        'Mezclar todo y cocinar - 15 min'
      ],
      'likes': 27,
    };

    final documentId = 'abc123'; // Este es el ID del documento Firestore

    final recipe = Recipe.fromJson(dataFromFirestore, documentId);
    final List<Recipe> recipes = [
      recipe
    ];


    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Receptes',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const SearchInput(),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: recipes.length,
                itemBuilder: (_, index) => RecipeCard(recipe: recipes[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}