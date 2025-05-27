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

                    return Recipe.fromJson(dataFromFirestore, documentId);
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
