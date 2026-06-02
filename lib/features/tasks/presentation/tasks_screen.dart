import 'package:dayforge/features/shell/presentation/placeholder_page.dart';
import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      icon: Icons.check_circle_outline,
      title: 'Tasks',
      subtitle: 'Task management will be added in Phase 4.',
    );
  }
}
