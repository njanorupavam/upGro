import 'dart:ui';
import 'package:dayforge/core/presentation/dayforge_ui.dart';
import 'package:dayforge/core/presentation/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _items = [
    ShellNavItem(
      label: 'Today',
      path: '/dashboard',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
    ),
    ShellNavItem(
      label: 'Tasks',
      path: '/tasks',
      icon: Icons.check_circle_outline,
      selectedIcon: Icons.check_circle,
    ),
    ShellNavItem(
      label: 'Focus',
      path: '/focus',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view,
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
      label: 'Insights',
      path: '/analytics',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 900;
        final body = AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(GoRouterState.of(context).matchedLocation),
            child: child,
          ),
        );

        return Scaffold(
          extendBody: true,
          appBar: AppBar(
            toolbarHeight: 62,
            titleSpacing: 20,
            title: Row(
              children: [
                _BrandMark(),
                const SizedBox(width: 12),
                Text(
                  'Upgro',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: context.dayforgeText,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 10),
                DayForgeBadge(_items[selectedIndex].label),
              ],
            ),
            actions: [
              Consumer(
                builder: (context, ref, child) {
                  final themeMode = ref.watch(themeModeProvider);
                  final isDarkTheme = themeMode == ThemeMode.dark;
                  return IconButton(
                    tooltip: isDarkTheme ? 'Switch to light mode' : 'Switch to dark mode',
                    onPressed: () {
                      ref.read(themeModeProvider.notifier).setThemeMode(
                            isDarkTheme ? ThemeMode.light : ThemeMode.dark,
                          );
                    },
                    icon: Icon(
                      isDarkTheme ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: () => context.go('/profile'),
                icon: const Icon(Icons.settings_outlined),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: useRail
                    ? Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
                            child: SizedBox(
                              width: 84,
                              child: FloatingVerticalGlassDock(
                                selectedIndex: selectedIndex,
                                onTap: (index) => context.go(_items[index].path),
                                items: _items,
                              ),
                            ),
                          ),
                          Expanded(child: body),
                        ],
                      )
                    : body,
              ),
              if (!useRail)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: SafeArea(
                    top: false,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: FloatingGlassDock(
                          selectedIndex: selectedIndex,
                          onTap: (index) => context.go(_items[index].path),
                          items: _items,
                        ),
                      ),
                    ),
                  ),
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

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.trending_up, color: Colors.white, size: 16),
    );
  }
}

class FloatingGlassDock extends StatelessWidget {
  const FloatingGlassDock({
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<ShellNavItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0x990F172A) : const Color(0xB3FFFFFF);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6);
    final shadowColor = isDark ? Colors.black.withOpacity(0.15) : const Color(0x0A1F2687);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: isSelected
                        ? BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 9,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class FloatingVerticalGlassDock extends StatelessWidget {
  const FloatingVerticalGlassDock({
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<ShellNavItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0x990F172A) : const Color(0xB3FFFFFF);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6);
    final shadowColor = isDark ? Colors.black.withOpacity(0.15) : const Color(0x0A1F2687);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Builder(
                  builder: (context) {
                    final item = items[i];
                    final isSelected = i == selectedIndex;

                    return GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        width: 64,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: isSelected
                            ? BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              )
                            : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                              size: 20,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 9,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
                if (i < items.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
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
