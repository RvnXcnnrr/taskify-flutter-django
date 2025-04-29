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
      theme: ThemeData.light(
        useMaterial3: true,
      ).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      darkTheme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
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
  String _searchQuery = '';
  TodoCategory? _filterCategory;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks: $e')),
        );
      }
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
    if (_addTodoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    try {
      final newTodo = TodoItem(
        id: const Uuid().v4(),
        title: _addTodoController.text.trim(),
        description: _addDescController.text.trim(),
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
            if (_todoController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a task title')),
              );
              return;
            }

            try {
              final updatedTodo = TodoItem(
                id: todo.id,
                title: _todoController.text.trim(),
                description: _descController.text.trim(),
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
    if (!mounted) return;
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _dueDate != null ? TimeOfDay.fromDateTime(_dueDate!) : TimeOfDay.now(),
    );
    if (!mounted) return;
    if (pickedTime == null) return;

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
    if (!mounted) return;
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _addDueDate != null ? TimeOfDay.fromDateTime(_addDueDate!) : TimeOfDay.now(),
    );
    if (!mounted) return;
    if (pickedTime == null) return;

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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: title == 'Add Task' ? _addTodoController : _todoController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: title == 'Add Task' ? _addDescController : _descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                maxLines: 3,
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
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: title == 'Add Task' ? _selectAddDueDate : _selectDueDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        title == 'Add Task'
                            ? (_addDueDate == null 
                                ? 'Set Due Date' 
                                : DateFormat('MMM dd, yyyy hh:mm a').format(_addDueDate!))
                            : (_dueDate == null 
                                ? 'Set Due Date' 
                                : DateFormat('MMM dd, yyyy hh:mm a').format(_dueDate!)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (title == 'Add Task' ? _addDueDate != null : _dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          if (title == 'Add Task') {
                            _addDueDate = null;
                          } else {
                            _dueDate = null;
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Save Task', style: TextStyle(fontSize: 16)),
                ),
              ),
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
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTodoBottomSheet(onSave: _addTodo),
    );
  }

  List<TodoItem> get _filteredTodos {
    return _todos.where((todo) {
      final matchesSearch = todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (todo.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesCategory = _filterCategory == null || todo.category == _filterCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterCategory == null,
                        onSelected: (selected) => setState(() => _filterCategory = null),
                      ),
                      ...TodoCategory.values.map((category) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(category.displayName),
                            selected: _filterCategory == category,
                            onSelected: (selected) => setState(() => _filterCategory = selected ? category : null),
                            avatar: Icon(category.icon, color: category.color),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTodos.isEmpty
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
                        _searchQuery.isEmpty && _filterCategory == null
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
                  itemCount: _filteredTodos.length,
                  itemBuilder: (context, index) {
                    final todo = _filteredTodos[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Slidable(
                        key: ValueKey(todo.id),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _editTodo(todo),
                              icon: Icons.edit,
                              label: 'Edit',
                              backgroundColor: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            SlidableAction(
                              onPressed: (_) => _deleteTodo(todo.id),
                              icon: Icons.delete,
                              label: 'Delete',
                              backgroundColor: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ],
                        ),
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _editTodo(todo),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        todo.category.icon,
                                        color: todo.category.color,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          todo.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                decoration: todo.isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                color: todo.isCompleted
                                                    ? Theme.of(context)
                                                        .disabledColor
                                                    : null,
                                              ),
                                        ),
                                      ),
                                      Checkbox(
                                        value: todo.isCompleted,
                                        onChanged: (_) => _toggleTodo(todo.id),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (todo.description?.isNotEmpty ?? false)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        todo.description!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              decoration: todo.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: todo.isCompleted
                                                  ? Theme.of(context)
                                                      .disabledColor
                                                  : null,
                                            ),
                                      ),
                                    ),
                                  if (todo.dueDate != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: todo.dueDate!.isBefore(DateTime.now()) && !todo.isCompleted
                                                ? Colors.red
                                                : Theme.of(context).disabledColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('MMM dd, yyyy hh:mm a').format(todo.dueDate!),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: todo.dueDate!.isBefore(DateTime.now()) && !todo.isCompleted
                                                  ? Colors.red
                                                  : Theme.of(context).disabledColor,
                                            ),
                                          ),
                                          if (todo.dueDate!.isBefore(DateTime.now()) && !todo.isCompleted)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 4),
                                              child: Text(
                                                '(Overdue)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        child: const Icon(Icons.add),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}