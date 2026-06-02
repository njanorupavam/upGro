import 'package:dayforge/features/shell/presentation/placeholder_page.dart';
import 'package:flutter/material.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      icon: Icons.flag_outlined,
      title: 'Goals',
      subtitle: 'Goal tracking will be added in Phase 6.',
    );
  }
}
