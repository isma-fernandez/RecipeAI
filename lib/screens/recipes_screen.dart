import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/search_input.dart';
import '../model/recipe.dart';

class IniciScreen extends StatelessWidget {
  const IniciScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipeQuery = FirebaseFirestore.instance
        .collection('recipes')
        .orderBy('likes', descending: true)
        .limit(1)
        .snapshots();

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
            const SearchInput(),
            const SizedBox(height: 24),
            Text(
              'Recepta del dia',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: recipeQuery,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Error cargant la recepta');
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Text('No hi ha receptes disponibles.');
                }

                final data = docs.first.data() as Map<String, dynamic>;
                final recipe = Recipe.fromJson(data, docs.first.id);

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white, // 🟢 Fondo blanco para mejor contraste
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
                                  color: Colors.black),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
