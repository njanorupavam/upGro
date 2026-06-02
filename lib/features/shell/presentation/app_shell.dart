import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.child,
    super.key,
  });

  final Widget child;

  static const _items = [
    ShellNavItem(
      label: 'Dashboard',
      path: '/dashboard',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard,
    ),
    ShellNavItem(
      label: 'Tasks',
      path: '/tasks',
      icon: Icons.check_circle_outline,
      selectedIcon: Icons.check_circle,
    ),
    ShellNavItem(
      label: 'Habits',
      path: '/habits',
      icon: Icons.repeat,
      selectedIcon: Icons.repeat_on,
    ),
    ShellNavItem(
      label: 'Goals',
      path: '/goals',
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag,
    ),
    ShellNavItem(
      label: 'Analytics',
      path: '/analytics',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    ShellNavItem(
      label: 'Profile',
      path: '/profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 900;
        final body = AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: KeyedSubtree(
            key: ValueKey(GoRouterState.of(context).matchedLocation),
            child: child,
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('DayForge'),
          ),
          body: useRail
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selectedIndex,
                      labelType: NavigationRailLabelType.all,
                      minWidth: 92,
                      onDestinationSelected: (index) {
                        context.go(_items[index].path);
                      },
                      destinations: [
                        for (final item in _items)
                          NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: Text(item.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                )
              : body,
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => context.go(_items[index].path),
                  destinations: [
                    for (final item in _items)
                      NavigationDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: item.label,
                      ),
                  ],
                ),
        );
      },
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _items.indexWhere((item) => location.startsWith(item.path));

    return index == -1 ? 0 : index;
  }
}

class ShellNavItem {
  const ShellNavItem({
    required this.label,
    required this.path,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
}
