// lib/widgets/search_input.dart

import 'package:flutter/material.dart';

class SearchInput extends StatelessWidget {
  final ValueChanged<String>? onChanged; // 👈 Añadido

  const SearchInput({super.key, this.onChanged}); // 👈 Añadido

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged, // 👈 Añadido
      decoration: InputDecoration(
        hintText: 'Cerca receptes, ingredients...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade900,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}
