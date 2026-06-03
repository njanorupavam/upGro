import 'dart:ui';

import 'package:flutter/material.dart';

const focusFlowBlue = Color(0xFF004AC6);
const focusFlowGreen = Color(0xFF006C49);
const focusFlowAmber = Color(0xFF784B00);
const focusFlowRed = Color(0xFFBA1A1A);

// Habit categories
enum HabitCategory {
  work('Work', Icons.work_outline, Color(0xFF3B82F6)),
  health('Health', Icons.favorite_outline, Color(0xFF10B981)),
  mind('Mind', Icons.self_improvement, Color(0xFF8B5CF6)),
  lifestyle('Lifestyle', Icons.wb_sunny_outlined, Color(0xFFF59E0B)),
  custom('Custom', Icons.star_outline, Color(0xFF64748B));

  const HabitCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

extension DayForgeColors on BuildContext {
  Color get dayforgeText => Theme.of(this).colorScheme.onSurface;
  Color get dayforgeMuted => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get dayforgeSurface => Theme.of(this).colorScheme.surface;
  Color get dayforgeSurfaceStrong => Theme.of(this).colorScheme.surfaceVariant;
  Color get dayforgeBorder => Theme.of(this).colorScheme.outlineVariant;
  Color get dayforgeCanvas => Theme.of(this).colorScheme.background;
}

class DayForgePage extends StatelessWidget {
  const DayForgePage({
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
    this.trailing,
    this.maxWidth = 430,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? trailing;
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        const Positioned.fill(child: DayForgeBackdrop()),
        SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: context.dayforgeText,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: context.dayforgeMuted,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (trailing != null) trailing!,
                          if (action != null) ...[
                            const SizedBox(width: 10),
                            action!,
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
                    sliver: SliverToBoxAdapter(child: child),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DayForgeBackdrop extends StatelessWidget {
  const DayForgeBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FF);
    final topLeftColor = isDark ? const Color(0x1A3B82F6) : const Color(0xFFD6E4FF);
    final topRightColor = isDark ? const Color(0x1410B981) : const Color(0xFFD6FFE6);

    return DecoratedBox(
      decoration: BoxDecoration(color: baseBgColor),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-1.0, -1.0),
                  radius: 1.4,
                  colors: [topLeftColor, Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.0, -1.0),
                  radius: 1.4,
                  colors: [topRightColor, Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _DotGridPainter(
                color: isDark ? const Color(0x0AFFFFFF) : const Color(0x06000000),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 20.0;
    for (var y = 10.0; y < size.height; y += spacing) {
      for (var x = 10.0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => oldDelegate.color != color;
}

class DayForgeCard extends StatelessWidget {
  const DayForgeCard({
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final resolvedColor = color ?? (isDark ? const Color(0x730F172A) : const Color(0x73FFFFFF));
    final borderColor = color != null 
        ? Colors.white.withOpacity(0.15) 
        : (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.5));
    final shadowColor = isDark ? Colors.black.withOpacity(0.15) : const Color(0x0A1F2687);

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: resolvedColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (color == null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(isDark ? 0.05 : 0.25),
                              Colors.white.withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.5],
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: padding,
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.dayforgeText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class IconBubble extends StatelessWidget {
  const IconBubble({
    required this.icon,
    this.color,
    this.background,
    super.key,
  });

  final IconData icon;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? theme.colorScheme.primary;
    final resolvedBg = background ?? resolvedColor.withOpacity(0.12);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: resolvedColor.withOpacity(0.2)),
      ),
      child: Icon(icon, color: resolvedColor, size: 20),
    );
  }
}

class DayForgeBadge extends StatelessWidget {
  const DayForgeBadge(
    this.label, {
    this.color,
    this.textColor,
    super.key,
  });

  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final resolvedBg = color ?? (isDark ? theme.colorScheme.primaryContainer.withOpacity(0.25) : theme.colorScheme.primaryContainer.withOpacity(0.12));
    final resolvedText = textColor ?? theme.colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: resolvedText.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: resolvedText,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.value,
    required this.label,
    this.size = 118,
    this.color,
    this.centerText,
    super.key,
  });

  final double value;
  final String label;
  final double size;
  final Color? color;
  /// Override center display text (e.g. "7/15" instead of "46%")
  final String? centerText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? theme.colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.outlineVariant.withOpacity(0.3),
              ),
              backgroundColor: Colors.transparent,
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(resolvedColor),
              backgroundColor: Colors.transparent,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerText ?? '${(value * 100).round()}%',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: centerText != null ? size * 0.18 : size * 0.22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  fontSize: size * 0.08,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// GridCell — animated checkbox cell for Focus Mode spreadsheet grid
// ────────────────────────────────────────────────────────────────────────────

class GridCell extends StatelessWidget {
  const GridCell({
    required this.isCompleted,
    required this.isToday,
    this.hasData = true,
    this.isFuture = false,
    this.onTap,
    this.size = 32.0,
    super.key,
  });

  final bool isCompleted;
  final bool isToday;
  final bool hasData;
  final bool isFuture;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bgColor;
    Color borderColor;
    Color iconColor;

    if (isFuture) {
      bgColor = Colors.transparent;
      borderColor = theme.colorScheme.outlineVariant.withOpacity(0.15);
      iconColor = Colors.transparent;
    } else if (isCompleted) {
      bgColor = isToday
          ? theme.colorScheme.primary
          : theme.colorScheme.primary.withOpacity(0.85);
      borderColor = theme.colorScheme.primary;
      iconColor = Colors.white;
    } else {
      bgColor = isDark
          ? Colors.white.withOpacity(0.03)
          : Colors.black.withOpacity(0.04);
      borderColor = isToday
          ? theme.colorScheme.primary.withOpacity(0.5)
          : theme.colorScheme.outlineVariant.withOpacity(isDark ? 0.25 : 0.4);
      iconColor = Colors.transparent;
    }

    return GestureDetector(
      onTap: (isFuture || !hasData) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: size,
        height: size,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: borderColor,
            width: isToday ? 1.5 : 1.0,
          ),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.check,
          size: size * 0.55,
          color: isCompleted ? iconColor : Colors.transparent,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// QuickCheckRow — compact row of today's habits with one-tap check-in
// ────────────────────────────────────────────────────────────────────────────

class QuickCheckRow extends StatelessWidget {
  const QuickCheckRow({
    required this.habits,
    required this.onCheckIn,
    super.key,
  });

  final List<({String id, String title, bool done, Color color})> habits;
  final void Function(String id) onCheckIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: habits.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final habit = habits[index];
          return GestureDetector(
            onTap: habit.done ? null : () => onCheckIn(habit.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: habit.done
                    ? habit.color.withOpacity(isDark ? 0.2 : 0.12)
                    : (isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.black.withOpacity(0.03)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: habit.done
                      ? habit.color.withOpacity(0.4)
                      : theme.colorScheme.outlineVariant.withOpacity(0.4),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: habit.done
                          ? habit.color
                          : Colors.transparent,
                      border: Border.all(
                        color: habit.done
                            ? habit.color
                            : theme.colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: habit.done ? Colors.white : Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    habit.title.split(' ').first,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: habit.done
                          ? habit.color
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontWeight:
                          habit.done ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
