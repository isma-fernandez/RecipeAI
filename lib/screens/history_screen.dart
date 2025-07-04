import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // referència a l’historial de l’usuari ordenat per data
    final user = FirebaseAuth.instance.currentUser!;
    final historyRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('history').orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de recetas')),
      body: StreamBuilder<QuerySnapshot>(
        stream: historyRef.snapshots(), // escolta en temps real
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('¡Aún no has escaneado recetas!'));

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  // miniatura de la recepta o icona per defecte
                  leading: data['imageUrl'] != null
                      ? Image.network(data['imageUrl'], width: 56, height: 56, fit: BoxFit.cover)
                      : const Icon(Icons.fastfood, size: 56),
                  // títol de la recepta
                  title: Text(data['name'] ?? 'Receta'),
                  // data de l’escaneig
                  subtitle: Text(data['timestamp'] != null
                      ? DateFormat('dd-MM-yyyy HH:mm').format((data['timestamp'] as Timestamp).toDate())
                      : ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
