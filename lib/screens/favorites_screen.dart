import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/recipe.dart';
import 'recipe_detail_screen.dart'; // importa la pantalla de detalle

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .orderBy('addedAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Recetas favoritas')),
      body: StreamBuilder<QuerySnapshot>(
        stream: favRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('¡Todavía no tienes favoritos!'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;

              // Crear Recipe desde datos de Firestore
              final recipe = Recipe(
                title: data['name'] ?? 'Receta',
                imageUrl: data['imageUrl'] ?? '',
                duration: (data['duration'] ?? 0) as int,
                numberOfPeople: (data['numberOfPeople'] ?? 0) as int,
                ingredients: List<String>.from(data['ingredients'] ?? []),
                steps: List<String>.from(data['steps'] ?? []),
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: data['imageUrl'] != null
                      ? Image.network(data['imageUrl'], width: 56, height: 56, fit: BoxFit.cover)
                      : const Icon(Icons.fastfood, size: 56),
                  title: Text(data['name'] ?? 'Receta'),
                  subtitle: Text(
                    data['addedAt'] != null
                        ? (data['addedAt'] as Timestamp).toDate().toString()
                        : '',
                  ),
                  onTap: () {
                    // Navegar a detalle con la receta construida
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: recipe),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}