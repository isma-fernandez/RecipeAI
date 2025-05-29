// lib/screens/recipes_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/search_input.dart';
import '../model/recipe.dart';
import 'recipe_detail_screen.dart';

class IniciScreen extends StatefulWidget {
  const IniciScreen({super.key});

  @override
  State<IniciScreen> createState() => _IniciScreenState();
}

class _IniciScreenState extends State<IniciScreen> {
  String searchQuery = '';
  List<Recipe> allRecipes = [];

  @override
  void initState() {
    super.initState();
    fetchAllRecipes();
  }

  Future<void> fetchAllRecipes() async {
    final snapshot = await FirebaseFirestore.instance.collection('recipes').get();
    final recipes = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Recipe.fromJson(data, doc.id);
    }).toList();

    setState(() {
      allRecipes = recipes;
    });
  }

  List<Recipe> get filteredRecipes {
    if (searchQuery.isEmpty) {
      // Mostrar receta con más likes
      allRecipes.sort((a, b) => b.likes.compareTo(a.likes));
      return allRecipes.isNotEmpty ? [allRecipes.first] : [];
    }

    return allRecipes.where((recipe) {
      final query = searchQuery.toLowerCase();
      final titleMatch = recipe.title.toLowerCase().contains(query);
      final ingredientMatch = recipe.ingredients.any(
            (ingredient) => ingredient.toLowerCase().contains(query),
      );
      return titleMatch || ingredientMatch;
    }).toList();
  }

  void onSearchChanged(String value) {
    setState(() {
      searchQuery = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = filteredRecipes;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Inici',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SearchInput(onChanged: onSearchChanged),
            const SizedBox(height: 24),
            Text(
              searchQuery.isEmpty ? 'Recepta del dia' : 'Resultats de la cerca',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (results.isEmpty)
              const Text('No hi ha resultats.')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final recipe = results[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(recipe: recipe),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Image.network(
                                recipe.imageUrl,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipe.title.isNotEmpty
                                        ? recipe.title
                                        : 'Recepta sense nom',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.people,
                                          size: 16, color: Colors.black),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${recipe.numberOfPeople} persones',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.black),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.schedule,
                                          size: 16, color: Colors.black),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${recipe.duration} min',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
