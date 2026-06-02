import 'package:dayforge/features/shell/presentation/placeholder_page.dart';
import 'package:flutter/material.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      icon: Icons.repeat,
      title: 'Habits',
      subtitle: 'Habit tracking will be added in Phase 5.',
    );
  }
}
