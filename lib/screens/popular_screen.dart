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
  // conjunt d’al·lèrgens definits pel perfil de l’usuari
  Set<String> _userAllergens = {};

  @override
  void initState() {super.initState();
    _loadAllergens();  // carregar preferències d’al·lèrgens
  }

  // consulta a Firestore per obtenir la llista d’al·lèrgens de l’usuari actual
  Future<void> _loadAllergens() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final list = snap.data()?['allergies'] as List<dynamic>? ?? [];
    setState(() => _userAllergens = list.map((e) => e.toString()).toSet());
  }

  @override
  Widget build(BuildContext context) {
    // consulta en temps real a les 20 receptes amb més likes
    final recipesStream = FirebaseFirestore.instance.collection('recipes').orderBy('likes', descending: true)
        .limit(20).snapshots();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // títol principal
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

                  final docs = snapshot.data?.docs ?? [];

                  // convertir documents en objectes Recipe i filtrar per al·lèrgens
                  final recipes = docs.map((d) {
                    final r = Recipe.fromJson(d.data() as Map<String, dynamic>, d.id,);
                    return r;
                  }).where((r) =>
                  _userAllergens.isEmpty || // cap filtre si no hi ha al·lèrgens
                      r.alergenos.every((a) => !_userAllergens.contains(a))).toList();

                  // missatge si no hi ha cap recepta visible per l’usuari
                  if (recipes.isEmpty) {
                    return const Center(child: Text('No hi ha receptes populars.'));
                  }

                  // llista de receptes amb targetes personalitzades
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
