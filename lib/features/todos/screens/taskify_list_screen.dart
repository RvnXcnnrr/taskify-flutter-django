import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../models/todo_item.dart';
import '../todo_provider.dart';
import '../widgets/todo_bottom_sheet.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_filter_chips.dart';
import '../widgets/todo_search_bar.dart';

class TaskifyListScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const TaskifyListScreen({
    super.key,
    required this.onThemeChanged,
  });

  @override
  State<TaskifyListScreen> createState() => _TaskifyListScreenState();
}

class _TaskifyListScreenState extends State<TaskifyListScreen> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    widget.onThemeChanged(_isDarkMode);
  }

  void _showAddTaskSheet() {
    final BuildContext localContext = context;
    showModalBottomSheet(
      context: localContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TodoBottomSheet(
        onSave: (title, description, dueDate, category) async {
          if (title.trim().isEmpty) {
            ScaffoldMessenger.of(localContext).showSnackBar(
              const SnackBar(content: Text('Please enter a task title')),
            );
            return;
          }
          final newTodo = TodoItem(
            id: const Uuid().v4(),
            title: title.trim(),
            description: description.trim(),
            isCompleted: false,
            dueDate: dueDate,
            category: category,
          );
          try {
            debugPrint('Adding todo: $newTodo');
            await Provider.of<TodoProvider>(localContext, listen: false).addTodo(newTodo);
            debugPrint('Todo added successfully');
            if (!localContext.mounted) return;
            debugPrint('Popping modal sheet');
            Navigator.of(localContext).pop();
          } catch (e, stackTrace) {
            debugPrint('Error adding todo: $e');
            debugPrint('$stackTrace');
            if (!localContext.mounted) return;
            ScaffoldMessenger.of(localContext).showSnackBar(
              SnackBar(content: Text('Failed to add task: $e')),
            );
          }
        },
        title: 'Add Task',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final todos = todoProvider.filteredTodos;
        final isLoading = todoProvider.isLoading;
        final searchQuery = todoProvider.searchQuery;
        final filterCategory = todoProvider.filterCategory;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Taskify'),
            centerTitle: false,
            actions: [
              IconButton(
                icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: _toggleTheme,
                tooltip: 'Toggle theme',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TodoSearchBar(
                      initialValue: searchQuery,
                      onChanged: (value) => todoProvider.setSearchQuery(value),
                    ),
                    const SizedBox(height: 8),
                    TodoFilterChips(
                      selectedCategory: filterCategory,
                      onCategorySelected: (category) => todoProvider.setFilterCategory(category),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : todos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 64,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isEmpty && filterCategory == null
                                  ? 'No tasks yet!\nAdd your first task.'
                                  : 'No tasks found.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).disabledColor,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: todos.length,
                        itemBuilder: (context, index) {
                          final todo = todos[index];
                          return TodoCard(
                            todo: todo,
                            onToggle: () => todoProvider.toggleTodoCompletion(todo.id),
                            onEdit: () => _editTodo(todo),
                            onDelete: () => todoProvider.deleteTodo(todo.id),
                          );
                        },
                      ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddTaskSheet,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _editTodo(TodoItem todo) {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final BuildContext localContext = context;
    showModalBottomSheet(
      context: localContext,
      isScrollControlled: true,
      builder: (context) {
        return TodoBottomSheet(
          title: 'Edit Task',
          initialTitle: todo.title,
          initialDescription: todo.description ?? '',
          initialDueDate: todo.dueDate,
          initialCategory: todo.category,
          onSave: (title, description, dueDate, category) async {
            if (title.trim().isEmpty) {
              ScaffoldMessenger.of(localContext).showSnackBar(
                const SnackBar(content: Text('Please enter a task title')),
              );
              return;
            }
            final updatedTodo = TodoItem(
              id: todo.id,
              title: title.trim(),
              description: description.trim(),
              isCompleted: todo.isCompleted,
              dueDate: dueDate,
              category: category,
            );
            try {
              await todoProvider.updateTodo(updatedTodo);
              if (!localContext.mounted) return;
              Navigator.of(localContext).pop();
            } catch (e) {
              if (!localContext.mounted) return;
              ScaffoldMessenger.of(localContext).showSnackBar(
                SnackBar(content: Text('Failed to update task: $e')),
              );
            }
          },
        );
      },
    );
  }
}
