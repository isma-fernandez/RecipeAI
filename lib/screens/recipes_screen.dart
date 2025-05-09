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
        title: 'Chocolate Chip Cookies',
        duration: 10,
        numberOfPeople: 12,
        imageUrl:
        'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?auto=format&fit=crop&w=800&q=60',
        ingredients: [
          '1 cup unsalted butter, softened',
          '1 cup granulated sugar',
          '1 cup packed brown sugar',
          '2 large eggs',
          '1 tsp vanilla extract',
          '3 cups all-purpose flour',
          '1 tsp baking soda',
          '½ tsp salt',
          '2 cups chocolate chips',
        ],
        steps: [
          'Pre-heat oven to 350 °F (175 °C). Line a baking sheet with parchment paper.',
          'Cream butter and both sugars until light and fluffy.',
          'Beat in eggs one at a time, then add vanilla extract.',
          'Whisk together flour, baking soda and salt; add to the wet mixture until just combined.',
          'Fold in chocolate chips.',
          'Drop rounded tablespoons of dough onto the baking sheet and bake 8-10 min.',
        ],
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