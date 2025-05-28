import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/recipe_card.dart';
import '../model/recipe.dart';

class PopularScreen extends StatelessWidget {
  const PopularScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Stream de recetas populares ordenadas por número de vistas
    final recipesStream = FirebaseFirestore.instance
        .collection('recipes')
        .orderBy('likes', descending: true)
        .limit(20)
        .snapshots();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Plats més populars',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: recipesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error cargando recetas'));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No hay recetas populares aún'));
                  }

                  final recipes = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Recipe.fromJson(data, doc.id);
                  }).toList();

                  return recipes.isNotEmpty
                      ? ListView.builder(
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return RecipeCard(recipe: recipe);
                    },
                  )
                      : const Center(child: Text('No hay recetas populares aún'));
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}