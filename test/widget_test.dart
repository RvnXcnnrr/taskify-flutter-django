import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskify/app/taskify_app.dart';

void main() {
  testWidgets('Add task smoke test', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const TaskifyApp());

    // Verify the initial state
    expect(find.text('No tasks yet'), findsOneWidget);

    // Tap the add button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify the add task dialog appears
    expect(find.text('Add Task'), findsOneWidget);
  });
}
