import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/recipe_card.dart';
import '../model/recipe.dart';

class PopularScreen extends StatefulWidget {
  const PopularScreen({super.key});

  @override
  State<PopularScreen> createState() => _PopularScreenState();
}

class _PopularScreenState extends State<PopularScreen> {
  Set<String> _userAllergens = {};

  @override
  void initState() {
    super.initState();
    _loadAllergens();
  }

  Future<void> _loadAllergens() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final list = snap.data()?['allergies'] as List<dynamic>? ?? [];
    setState(() => _userAllergens = list.map((e) => e.toString()).toSet());
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Plats més populars',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: recipesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];

                  final recipes = docs.map((d) {
                    final r = Recipe.fromJson(d.data() as Map<String, dynamic>, d.id);
                    return r;
                  }).where((r) => _userAllergens.isEmpty ||
                      r.alergenos.every((a) => !_userAllergens.contains(a))).toList();

                  if (recipes.isEmpty) {
                    return const Center(child: Text('No hi ha receptes populars.'));
                  }

                  return ListView.builder(
                    itemCount: recipes.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: RecipeCard(recipe: recipes[i]),
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
