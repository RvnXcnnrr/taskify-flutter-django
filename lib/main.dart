import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/taskify_app.dart';
import 'features/todos/todo_provider.dart';
import 'app/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()..loadTodos()),
      ],
      child: const TaskifyApp(),
    ),
  );
}
