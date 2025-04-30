import 'package:flutter/material.dart';

import '../../models/todo_item.dart';
import '../../services/todo_service.dart';

class TodoProvider extends ChangeNotifier {
  List<TodoItem> _todos = [];
  bool _isLoading = false;
  String _searchQuery = '';
  TodoCategory? _filterCategory;

  List<TodoItem> get todos => _todos;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  TodoCategory? get filterCategory => _filterCategory;

  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();
    try {
      _todos = await TodoService.fetchTodos();
    } catch (e) {
      // Handle error as needed
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterCategory(TodoCategory? category) {
    _filterCategory = category;
    notifyListeners();
  }

  List<TodoItem> get filteredTodos {
    return _todos.where((todo) {
      final matchesSearch = todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (todo.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesCategory = _filterCategory == null || todo.category == _filterCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> addTodo(TodoItem todo) async {
    try {
      final createdTodo = await TodoService.addTodo(todo);
      _todos.add(createdTodo);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTodo(TodoItem todo) async {
    try {
      await TodoService.updateTodo(todo);
      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _todos[index] = todo;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      await TodoService.deleteTodo(id);
      _todos.removeWhere((todo) => todo.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleTodoCompletion(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      final updatedTodo = TodoItem(
        id: todo.id,
        title: todo.title,
        description: todo.description,
        isCompleted: !todo.isCompleted,
        dueDate: todo.dueDate,
        category: todo.category,
      );
      await updateTodo(updatedTodo);
    }
  }
}
