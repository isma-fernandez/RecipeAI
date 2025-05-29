import 'package:flutter/material.dart';

class SearchInput extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final String hintText;

  const SearchInput({
    Key? key,
    this.onChanged,
    this.hintText = 'Cerca receptes…',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onChanged: onChanged,
    );
  }
}
