import 'package:flutter/material.dart';

import '../../../models/todo_item.dart';

class TodoFilterChips extends StatelessWidget {
  final TodoCategory? selectedCategory;
  final ValueChanged<TodoCategory?> onCategorySelected;

  const TodoFilterChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: selectedCategory == null,
            onSelected: (selected) => onCategorySelected(selected ? null : selectedCategory),
          ),
          ...TodoCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(category.displayName),
                selected: selectedCategory == category,
                onSelected: (selected) => onCategorySelected(selected ? category : null),
                avatar: Icon(category.icon, color: category.color),
              ),
            );
          }),
        ],
      ),
    );
  }
}
