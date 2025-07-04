import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../model/recipe.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // obtenir usuari actual i referència a la col·lecció de favorits
    final user = FirebaseAuth.instance.currentUser!;
    final favRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites').orderBy('addedAt', descending: true); // ordenats per data

    return Scaffold(
      appBar: AppBar(title: const Text('Recetas favoritas')),
      body: StreamBuilder<QuerySnapshot>(
        stream: favRef.snapshots(), // escolta canvis en els favorits
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('¡Todavía no tienes favoritos!'));

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final favDoc = docs[i];
              final recipeId = favDoc.id; // ID de la recepta guardada

              return StreamBuilder<DocumentSnapshot>(
                // escolta la recepta original a partir del seu ID
                stream: FirebaseFirestore.instance.collection('recipes').doc(recipeId).snapshots(),
                builder: (context, recipeSnapshot) {
                  if (recipeSnapshot.connectionState == ConnectionState.waiting) return const ListTile(title: Text('Cargando...'));
                  if (!recipeSnapshot.hasData || !recipeSnapshot.data!.exists) return const ListTile(title: Text('Receta no disponible'));

                  // convertir document a objecte Recipe
                  final recipeData = recipeSnapshot.data!.data() as Map<String, dynamic>;
                  final recipe = Recipe.fromJson(recipeData, recipeId);

                  // obtenir data d’afegit a favorits
                  final addedAt = favDoc['addedAt'] as Timestamp?;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      // miniatura o icona
                      leading: recipe.imageUrl.isNotEmpty
                          ? Image.network(recipe.imageUrl, width: 56, height: 56, fit: BoxFit.cover)
                          : const Icon(Icons.fastfood, size: 56),
                      // títol i data
                      title: Text(recipe.title),
                      subtitle: Text(addedAt != null ? DateFormat('dd-MM-yyyy HH:mm').format(addedAt.toDate()) : ''),
                      // nombre de likes
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.thumb_up, size: 16),
                          const SizedBox(width: 4),
                          Text('${recipe.likes}'),
                        ],
                      ),
                      // obrir detall de recepta
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)));
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
