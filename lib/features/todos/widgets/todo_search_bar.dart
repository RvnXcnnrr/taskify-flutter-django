import 'package:flutter/material.dart';

class TodoSearchBar extends StatelessWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const TodoSearchBar({
    super.key,
    this.initialValue = '',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search tasks...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }
}
