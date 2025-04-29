// lib/models/todo_item.dart
import 'package:flutter/material.dart';

enum TodoCategory { personal, work, study, other }

extension TodoCategoryExtension on TodoCategory {
  String get name {
    switch (this) {
      case TodoCategory.personal:
        return 'personal';
      case TodoCategory.work:
        return 'work';
      case TodoCategory.study:
        return 'study';
      case TodoCategory.other:
        return 'other';
    }
  }

  IconData get icon {
    switch (this) {
      case TodoCategory.personal:
        return Icons.person;
      case TodoCategory.work:
        return Icons.work;
      case TodoCategory.study:
        return Icons.school;
      case TodoCategory.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case TodoCategory.personal:
        return Colors.teal;
      case TodoCategory.work:
        return Colors.orange;
      case TodoCategory.study:
        return Colors.purple;
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
  bool isCompleted;
  final DateTime? dueDate;
  final TodoCategory category;

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.dueDate,
    this.category = TodoCategory.personal,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['is_completed'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      category: _parseCategory(json['category']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'due_date': dueDate?.toIso8601String(),
      'category': category.name,
    };
  }

  static TodoCategory _parseCategory(String category) {
    switch (category) {
      case 'work':
        return TodoCategory.work;
      case 'study':
        return TodoCategory.study;
      case 'other':
        return TodoCategory.other;
      default:
        return TodoCategory.personal;
    }
  }
}