import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/recipe.dart';
import 'recipe_detail_screen.dart';

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
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              // Construimos el modelo Recipe directamente
              final recipe = Recipe.fromJson(data, doc.id);

              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: recipe.imageUrl.isNotEmpty
                      ? Image.network(
                    recipe.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  )
                      : const Icon(Icons.fastfood, size: 56),
                  title: Text(recipe.title),
                  subtitle: Text(
                    data['addedAt'] != null
                        ? (data['addedAt'] as Timestamp)
                        .toDate()
                        .toString()
                        : '',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.thumb_up, size: 16),
                      const SizedBox(width: 4),
                      Text('${recipe.likes}'),
                    ],
                  ),
                  onTap: () {
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
