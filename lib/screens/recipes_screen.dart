import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Set<String> userAllergens = {};

  @override
  void initState() {
    super.initState();
    fetchAllRecipes(); fetchUserAllergens(); // càrrega inicial
  }

  // Obté totes les receptes de la base de dades
  Future<void> fetchAllRecipes() async {
    final snapshot = await FirebaseFirestore.instance.collection('recipes').get();
    final recipes = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Recipe.fromJson(data, doc.id);
    }).toList();
    setState(() => allRecipes = recipes);
  }

  // Llegeix els al·lèrgens de l’usuari
  Future<void> fetchUserAllergens() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>;
      setState(() => userAllergens = Set<String>.from(data['allergies'] ?? <String>[]));
    }
  }

  bool _isSafe(Recipe r) => !r.alergenos.any((a) => userAllergens.contains(a));

  // Filtra les receptes segons la cerca i els al·lèrgens
  List<Recipe> get filteredRecipes {
    if (searchQuery.isEmpty) return [];
    final query = searchQuery.toLowerCase();
    return allRecipes.where((r) {
      final match = r.title.toLowerCase().contains(query) ||
          r.ingredients.any((ing) => ing.toLowerCase().contains(query));
      return match && _isSafe(r);
    }).toList();
  }

  // Recepta amb més likes i sense al·lèrgens
  Recipe? get recipeOfTheDay {
    final safe = allRecipes.where(_isSafe).toList();
    if (safe.isEmpty) return null;
    safe.sort((a, b) => b.likes.compareTo(a.likes));
    return safe.first;
  }

  // Ràpides (≤20 min)
  List<Recipe> get quickRecipes =>
      allRecipes.where(_isSafe).where((r) => r.duration <= 20).toList();

  // Per a grups (≥4 persones)
  List<Recipe> get groupRecipes =>
      allRecipes.where(_isSafe).where((r) => r.numberOfPeople >= 4).toList();

  void onSearchChanged(String value) => setState(() => searchQuery = value.trim());

  @override
  Widget build(BuildContext context) {
    final results = filteredRecipes;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text('Inici', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SearchInput(onChanged: onSearchChanged), // input de cerca
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  if (searchQuery.isNotEmpty) ...[
                    sectionTitle('Resultats de la cerca'),
                    if (results.isNotEmpty) ...results.map(buildRecipeCard).toList()
                    else const Text('No hi ha resultats.')
                  ] else ...[
                    sectionTitle('Recepta del dia'),
                    if (recipeOfTheDay != null) buildRecipeCard(recipeOfTheDay!)
                    else const Text('No hi ha cap recepta destacada.'),
                    sectionTitle('Receptes ràpides'),
                    if (quickRecipes.isNotEmpty) ...quickRecipes.map(buildRecipeCard).toList()
                    else const Text('No hi ha receptes ràpides.'),
                    sectionTitle('Per a grups'),
                    if (groupRecipes.isNotEmpty) ...groupRecipes.map(buildRecipeCard).toList()
                    else const Text('No hi ha receptes per a grups.'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
  );

  // Targeta de recepta clicable
  Widget buildRecipeCard(Recipe r) => GestureDetector(
    onTap: () {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)));
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            child: Image.network(r.imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title.isNotEmpty ? r.title : 'Recepta sense nom',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.people, size: 16, color: Colors.black),
                  const SizedBox(width: 4),
                  Text('${r.numberOfPeople} persones',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black)),
                  const SizedBox(width: 12),
                  const Icon(Icons.schedule, size: 16, color: Colors.black),
                  const SizedBox(width: 4),
                  Text('${r.duration} min',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black)),
                ]),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
