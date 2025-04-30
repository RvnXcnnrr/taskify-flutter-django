import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/todos/screens/taskify_list_screen.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';

class TaskifyApp extends StatelessWidget {
  const TaskifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Taskify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: TaskifyListScreen(
        onThemeChanged: (isDark) => themeProvider.toggleTheme(isDark),
      ),
    );
  }
}
