// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models/todo_item.dart';
import 'services/todo_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  runApp(TaskifyApp(isDarkMode: isDarkMode));
}

class TaskifyApp extends StatefulWidget {
  final bool isDarkMode;

  const TaskifyApp({super.key, required this.isDarkMode});

  @override
  State<TaskifyApp> createState() => _TaskifyAppState();
}

class _TaskifyAppState extends State<TaskifyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void toggleTheme(bool isDark) async {
    setState(() {
      _isDarkMode = isDark;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: TaskifyListScreen(
        isDarkMode: _isDarkMode,
        onThemeChanged: toggleTheme,
      ),
    );
  }
}

class TaskifyListScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const TaskifyListScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<TaskifyListScreen> createState() => _TaskifyListScreenState();
}

class _TaskifyListScreenState extends State<TaskifyListScreen> {
  List<TodoItem> _todos = [];
  late bool _isDarkMode;
  bool _isLoading = true;

  final TextEditingController _addTodoController = TextEditingController();
  final TextEditingController _addDescController = TextEditingController();
  DateTime? _addDueDate;
  TodoCategory _addSelectedCategory = TodoCategory.personal;

  final TextEditingController _todoController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime? _dueDate;
  TodoCategory _selectedCategory = TodoCategory.personal;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    setState(() => _isLoading = true);
    try {
      final todos = await TodoService.fetchTodos();
      setState(() => _todos = todos);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tasks: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    widget.onThemeChanged(_isDarkMode);
  }

  Future<void> _addTodo() async {
    if (_addTodoController.text.isNotEmpty) {
      try {
        final newTodo = TodoItem(
          id: const Uuid().v4(),
          title: _addTodoController.text,
          description: _addDescController.text,
          isCompleted: false,
          dueDate: _addDueDate,
          category: _addSelectedCategory,
        );
        
        final createdTodo = await TodoService.addTodo(newTodo);
        
        setState(() {
          _todos.add(createdTodo);
          _addTodoController.clear();
          _addDescController.clear();
          _addDueDate = null;
          _addSelectedCategory = TodoCategory.personal;
        });
        
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add task: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      try {
        final updatedTodo = TodoItem(
          id: _todos[index].id,
          title: _todos[index].title,
          description: _todos[index].description,
          isCompleted: !_todos[index].isCompleted,
          dueDate: _todos[index].dueDate,
          category: _todos[index].category,
        );
        
        await TodoService.updateTodo(updatedTodo);
        
        setState(() {
          _todos[index] = updatedTodo;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update task: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteTodo(String id) async {
    try {
      await TodoService.deleteTodo(id);
      setState(() {
        _todos.removeWhere((todo) => todo.id == id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: $e')),
        );
      }
    }
  }

  Future<void> _editTodo(TodoItem todo) async {
    _todoController.text = todo.title;
    _descController.text = todo.description ?? '';
    _dueDate = todo.dueDate;
    _selectedCategory = todo.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _buildTodoBottomSheet(
          onSave: () async {
            try {
              final updatedTodo = TodoItem(
                id: todo.id,
                title: _todoController.text,
                description: _descController.text,
                isCompleted: todo.isCompleted,
                dueDate: _dueDate,
                category: _selectedCategory,
              );
              
              await TodoService.updateTodo(updatedTodo);
              
              setState(() {
                final index = _todos.indexWhere((t) => t.id == todo.id);
                _todos[index] = updatedTodo;
              });
              
              _todoController.clear();
              _descController.clear();
              _dueDate = null;
              _selectedCategory = TodoCategory.personal;
              if (mounted) Navigator.of(context).pop();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update task: $e')),
                );
              }
            }
          },
          title: 'Edit Task',
        );
      },
    );
  }

  Future<void> _selectDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _dueDate != null ? TimeOfDay.fromDateTime(_dueDate!) : TimeOfDay.now(),
    );
    if (!mounted || pickedTime == null) return;

    setState(() {
      _dueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _selectAddDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _addDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _addDueDate != null ? TimeOfDay.fromDateTime(_addDueDate!) : TimeOfDay.now(),
    );
    if (!mounted || pickedTime == null) return;

    setState(() {
      _addDueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Widget _buildTodoBottomSheet({required VoidCallback onSave, String title = 'Add Task'}) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextField(
                controller: title == 'Add Task' ? _addTodoController : _todoController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: title == 'Add Task' ? _addDescController : _descController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TodoCategory>(
                value: title == 'Add Task' ? _addSelectedCategory : _selectedCategory,
                items: TodoCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(category.icon, color: category.color),
                        const SizedBox(width: 8),
                        Text(category.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      if (title == 'Add Task') {
                        _addSelectedCategory = value;
                      } else {
                        _selectedCategory = value;
                      }
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: title == 'Add Task' ? _selectAddDueDate : _selectDueDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(title == 'Add Task'
                    ? (_addDueDate == null ? 'Pick Due Date' : DateFormat('MMM dd, yyyy hh:mm a').format(_addDueDate!))
                    : (_dueDate == null ? 'Pick Due Date' : DateFormat('MMM dd, yyyy hh:mm a').format(_dueDate!))),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onSave, child: const Text('Save Task')),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildTodoBottomSheet(onSave: _addTodo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taskify'),
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];
                return Slidable(
                  key: ValueKey(todo.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => _editTodo(todo),
                        icon: Icons.edit,
                        label: 'Edit',
                        backgroundColor: Colors.blue,
                      ),
                      SlidableAction(
                        onPressed: (_) => _deleteTodo(todo.id),
                        icon: Icons.delete,
                        label: 'Delete',
                        backgroundColor: Colors.red,
                      ),
                    ],
                  ),
                  child: CheckboxListTile(
                    title: Text(todo.title,
                        style: TextStyle(decoration: todo.isCompleted ? TextDecoration.lineThrough : null)),
                    subtitle: todo.dueDate != null
                        ? Text(DateFormat('MMM dd, yyyy hh:mm a').format(todo.dueDate!))
                        : Text(todo.description ?? ''),
                    value: todo.isCompleted,
                    onChanged: (_) => _toggleTodo(todo.id),
                    secondary: Icon(todo.category.icon, color: todo.category.color),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}