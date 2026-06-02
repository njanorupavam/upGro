import 'package:flutter/material.dart';

const dayforgeBlue = Color(0xFF3158F6);
const dayforgeInk = Color(0xFF101828);
const dayforgeMuted = Color(0xFF667085);
const dayforgeCanvas = Color(0xFFF6F8FF);
const dayforgeCard = Color(0xFFFFFFFF);
const dayforgeSoftBlue = Color(0xFFEAF0FF);
const dayforgeGreen = Color(0xFF20C997);
const dayforgeAmber = Color(0xFFFFB020);

class DayForgePage extends StatelessWidget {
  const DayForgePage({
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
    this.trailing,
    this.maxWidth = 520,
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
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: dayforgeInk,
                                        ),
                                  ),
                                  if (subtitle != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: dayforgeMuted),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            ?trailing,
                            if (action != null) ...[
                              const SizedBox(width: 10),
                              action!,
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 108),
                  sliver: SliverToBoxAdapter(child: child),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DayForgeCard extends StatelessWidget {
  const DayForgeCard({
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E9F7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
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
              color: dayforgeInk,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

class IconBubble extends StatelessWidget {
  const IconBubble({
    required this.icon,
    this.color = dayforgeBlue,
    this.background = dayforgeSoftBlue,
    super.key,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class DayForgeBadge extends StatelessWidget {
  const DayForgeBadge(
    this.label, {
    this.color = dayforgeSoftBlue,
    this.textColor = dayforgeBlue,
    super.key,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
