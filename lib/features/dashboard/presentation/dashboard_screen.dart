import 'package:dayforge/features/shell/presentation/placeholder_page.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      icon: Icons.space_dashboard_outlined,
      title: 'Dashboard',
      subtitle: 'Your productivity overview will appear here in Phase 7.',
    );
  }
}
