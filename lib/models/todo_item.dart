import 'package:flutter/material.dart';

enum TodoCategory {
  personal,
  work,
  study,
  other,
}

extension TodoCategoryExtension on TodoCategory {
  IconData get icon {
    switch (this) {
      case TodoCategory.personal:
        return Icons.person;
      case TodoCategory.work:
        return Icons.work;
      case TodoCategory.study:
        return Icons.school;
      case TodoCategory.other:
        return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case TodoCategory.personal:
        return Colors.blue;
      case TodoCategory.work:
        return Colors.green;
      case TodoCategory.study:
        return Colors.orange;
      case TodoCategory.other:
        return Colors.grey;
    }
  }

  String get displayName {
    switch (this) {
      case TodoCategory.personal:
        return 'Personal';
      case TodoCategory.work:
        return 'Work';
      case TodoCategory.study:
        return 'Study';
      case TodoCategory.other:
        return 'Other';
    }
  }
}

class TodoItem {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? dueDate;
  final TodoCategory category;

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    this.dueDate,
    required this.category,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    TodoCategory? category,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
    );
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      category: TodoCategory.values.firstWhere(
        (e) => e.toString() == 'TodoCategory.${json['category'] ?? 'other'}',
        orElse: () => TodoCategory.other,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'due_date': dueDate?.toIso8601String(),
      'category': category.toString().split('.').last,
    };
  }
}
