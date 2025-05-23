import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/recipe_card.dart';
import '../model/recipe.dart';

class PopularScreen extends StatelessWidget {
  const PopularScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Consulta los platos ordenados por número de vistas descendente (más populares primero)
    final recipesStream = FirebaseFirestore.instance
        .collection('recipes')
        .orderBy('views', descending: true)
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
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: recipesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No hi ha plats populars encara.'));
                  }
                  final recipes = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    // Si tu model Recipe espera estos campos, ¡los conviertes!
                    return Recipe(
                      title: data['name'] ?? 'Sense nom',
                      duration: data['duration'] ?? 0,
                      numberOfPeople: data['numberOfPeople'] ?? 1,
                      imageUrl: data['imageUrl'] ?? '',
                      ingredients: List<String>.from(data['ingredients'] ?? []),
                      steps: List<String>.from(data['steps'] ?? []),
                      // Si quieres, puedes añadir aquí otros campos de Recipe
                    );
                  }).toList();

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 3 / 4,
                    ),
                    itemCount: recipes.length,
                    itemBuilder: (_, index) => RecipeCard(recipe: recipes[index]),
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
