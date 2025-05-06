import 'package:flutter/material.dart';
import '../widgets/search_input.dart';
import '../widgets/recipe_card.dart';
import '../model/recipe.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: temporal per mostrar alguna cosa per ara
    final List<Recipe> recipes = [
      Recipe(
        title: 'Recepta guardada 1',
        duration: 10,
        numberOfPeople: 2,
        imageUrl:
        'https://images.unsplash.com/photo-1565958011703-44f9829ba187?auto=format&fit=crop&w=800&q=60',
        steps: ['pas 1', 'pas 2', 'pas 3'],
        ingredients: ['ingredient 1', 'ingredient 2', 'ingredient 3']
      ),
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