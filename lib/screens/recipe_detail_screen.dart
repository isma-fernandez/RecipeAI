import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/recipe.dart';
import 'dart:async';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  User? user;
  bool isFav = false, isLoading = true;
  int likes = 0;
  late final StreamSubscription<User?> _authSub;

  @override
  void initState() {
    super.initState();
    likes = widget.recipe.likes;

    // Subscriu als canvis d’usuari autenticat
    _authSub = FirebaseAuth.instance.authStateChanges().listen((usr) {
      if (!mounted) return;
      setState(() => user = usr);
      usr != null ? _checkIfFavorite(usr.uid) : setState(() {
        isFav = false; isLoading = false;
      });
    });

    // Subscriu als canvis de likes de la recepta
    _subscribeToLikes();
  }

  void _subscribeToLikes() {
    FirebaseFirestore.instance.collection('recipes').doc(widget.recipe.id)
        .snapshots().listen((snap) {
      if (!mounted || !snap.exists) return;
      final data = snap.data();
      if (data != null && data.containsKey('likes')) {
        setState(() => likes = data['likes'] ?? 0);
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel(); // Netegem subscripció
    super.dispose();
  }

  // Comprova si la recepta ja és un favorit de l’usuari
  Future<void> _checkIfFavorite(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('favorites')
        .doc(widget.recipe.id).get();
    if (!mounted) return;
    setState(() {
      isFav = doc.exists;
      isLoading = false;
    });
  }

  // Afegeix o elimina la recepta dels favorits, i actualitza els likes
  Future<void> _toggleFavorite() async {
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users').doc(user!.uid).collection('favorites')
        .doc(widget.recipe.id);
    final recipeRef = FirebaseFirestore.instance.collection('recipes')
        .doc(widget.recipe.id);
    final recipeSnap = await recipeRef.get();
    final currentLikes = (recipeSnap.data()?['likes'] ?? 0) as int;

    if (isFav) {
      await favRef.delete();
      await recipeRef.update({'likes': currentLikes > 0 ? FieldValue.increment(-1) : 0});
    } else {
      await favRef.set({
        'nombre_receta': widget.recipe.title,
        'imagen': widget.recipe.imageUrl,
        'addedAt': FieldValue.serverTimestamp(),
        'tiempo_total': widget.recipe.duration,
        'personas': widget.recipe.numberOfPeople,
        'ingredientes': widget.recipe.ingredients,
        'pasos_con_tiempo': widget.recipe.steps,
      });
      await recipeRef.update({'likes': FieldValue.increment(1)});
    }

    if (!mounted) return;
    setState(() => isFav = !isFav);

    // Mostra missatge de confirmació
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isFav ? 'Agregado a favoritos' : 'Eliminado de favoritos'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Capçalera amb imatge i acció de favorits
          SliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            expandedHeight: 250, pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.recipe.title),
              background: Image.network(widget.recipe.imageUrl, fit: BoxFit.cover),
            ),
            actions: user == null ? null : [
              IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                    color: Colors.redAccent),
                onPressed: isLoading ? null : _toggleFavorite,
              )
            ],
          ),

          // Cos principal amb informació i passos
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Informació bàsica (persones, temps, likes)
                Row(children: [
                  _InfoChip(icon: Icons.people, label: '${widget.recipe.numberOfPeople}'),
                  const SizedBox(width: 12),
                  _InfoChip(icon: Icons.schedule, label: '${widget.recipe.duration} min'),
                  const SizedBox(width: 12),
                  _InfoChip(icon: Icons.thumb_up, label: '$likes'),
                ]),
                const SizedBox(height: 24),

                // Llista d’ingredients
                Text('Ingredients', style: Theme.of(context)
                    .textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...widget.recipe.ingredients.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [const Text('• '), Expanded(child: Text(e))],
                    ))),

                const SizedBox(height: 24),

                // Passos de preparació numerats
                Text('Method', style: Theme.of(context)
                    .textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...widget.recipe.steps.asMap().entries.map((e) =>
                    _StepTile(number: e.key + 1, text: e.value)),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// Icona + text per mostrar informació compacta
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

// Bloc visual per a cada pas de la recepta
class _StepTile extends StatelessWidget {
  final int number;
  final String text;
  const _StepTile({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Text('$number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondary,
                )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
