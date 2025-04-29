// lib/services/todo_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/todo_item.dart';

class TodoService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/tasks/'; // Use 10.0.2.2 for Android emulator

  static Future<List<TodoItem>> fetchTodos() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => TodoItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load tasks: ${response.statusCode}');
    }
  }

  static Future<TodoItem> addTodo(TodoItem todo) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(todo.toJson()),
    );
    if (response.statusCode == 201) {
      return TodoItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add task: ${response.statusCode}');
    }
  }

  static Future<void> updateTodo(TodoItem todo) async {
    final response = await http.put(
      Uri.parse('$baseUrl${todo.id}/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(todo.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update task: ${response.statusCode}');
    }
  }

  static Future<void> deleteTodo(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl$id/'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete task: ${response.statusCode}');
    }
  }
}