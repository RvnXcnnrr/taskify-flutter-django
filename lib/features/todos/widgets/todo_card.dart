import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../models/todo_item.dart';

class TodoCard extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = todo.dueDate != null && todo.dueDate!.isBefore(DateTime.now()) && !todo.isCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Slidable(
        key: ValueKey(todo.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              icon: Icons.edit,
              label: 'Edit',
              backgroundColor: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (_) => onDelete(),
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
            onTap: onEdit,
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                                color: todo.isCompleted ? Theme.of(context).disabledColor : null,
                              ),
                        ),
                      ),
                      Checkbox(
                        value: todo.isCompleted,
                        onChanged: (_) => onToggle(),
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                              color: todo.isCompleted ? Theme.of(context).disabledColor : null,
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
                            color: isOverdue ? Colors.red : Theme.of(context).disabledColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy hh:mm a').format(todo.dueDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue ? Colors.red : Theme.of(context).disabledColor,
                            ),
                          ),
                          if (isOverdue)
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
  }
}
