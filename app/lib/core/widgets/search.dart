import 'package:flutter/material.dart';

class Search extends StatelessWidget {
  const Search({super.key});
  @override
  Widget build(BuildContext context) => TextField(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.blue.shade200),
            gapPadding: 10,
          ),
          fillColor: Colors.grey.shade100,
        ),
      );
}
