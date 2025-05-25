import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/recipe.dart';
import 'dart:async';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({Key? key, required this.recipe}) : super(key: key);

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  User? user;
  bool isFav = false;
  bool isLoading = true;
  late final StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();

    // Escuchar cambios de autenticación y actualizar estado
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((usr) {
      if (!mounted) return; // evitar setState si widget desmontado
      setState(() {
        user = usr;
      });

      if (usr != null) {
        _checkIfFavorite(usr.uid);
      } else {
        setState(() {
          isFav = false;
          isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _checkIfFavorite(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(widget.recipe.title)
        .get();

    if (!mounted) return; // evitar setState si ya desmontado
    setState(() {
      isFav = doc.exists;
      isLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(widget.recipe.title);

    if (isFav) {
      await favRef.delete();
    } else {
      await favRef.set({
        'name': widget.recipe.title,
        'imageUrl': widget.recipe.imageUrl,
        'addedAt': FieldValue.serverTimestamp(),
        'duration': widget.recipe.duration,
        'numberOfPeople': widget.recipe.numberOfPeople,
        'ingredients': widget.recipe.ingredients,
        'steps': widget.recipe.steps,
      });
    }

    if (!mounted) return;
    setState(() {
      isFav = !isFav;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFav ? 'Agregado a favoritos' : 'Eliminado de favoritos'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.recipe.title),
              background: Image.network(
                widget.recipe.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            actions: user == null
                ? null
                : [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: Colors.redAccent,
                ),
                onPressed: isLoading ? null : _toggleFavorite,
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Row(
                    children: [
                      _InfoChip(icon: Icons.people, label: '${widget.recipe.numberOfPeople}'),
                      const SizedBox(width: 12),
                      _InfoChip(icon: Icons.schedule, label: '${widget.recipe.duration} min'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Ingredientes
                  Text('Ingredients',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...widget.recipe.ingredients.map(
                        (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(e)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pasos
                  Text('Method',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...widget.recipe.steps.asMap().entries.map(
                        (entry) => _StepTile(number: entry.key + 1, text: entry.value),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({Key? key, required this.icon, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: Colors.grey.shade900,
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int number;
  final String text;

  const _StepTile({Key? key, required this.number, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.blueAccent,
            child: Text('$number',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
